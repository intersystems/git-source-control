Include SourceControl.Git

Class UnitTest.SourceControl.Git.ProductionDecomposition Extends %UnitTest.TestCase
{

Parameter ProductionName = "UnitTest.SampleProduction";

Property SourceControlGlobal [ MultiDimensional ];

Property InitialExtension As %String [ InitialExpression = {##class(%Studio.SourceControl.Interface).SourceControlClassGet()} ];

Method TestDecomposeExistingProduction()
{
    do $System.OBJ.Delete(..#ProductionName)
    set settings = ##class(SourceControl.Git.Settings).%New()
    set settings.decomposeProductions = 0
    $$$ThrowOnError(settings.%Save())
    $$$ThrowOnError(##class(SourceControl.Git.Production).CreateProduction(..#ProductionName))
    do ..ReplaceProductionDefinition("ProductionDefinition1")
    $$$ThrowOnError(##class(SourceControl.Git.Utils).AddToSourceControl(..#ProductionName_".cls"))
    do $$$AssertTrue(##class(SourceControl.Git.Utils).IsInSourceControl(..#ProductionName_".cls"))
    $$$ThrowOnError(##class(SourceControl.Git.Utils).Commit(..#ProductionName_".cls"))

    set settings.decomposeProductions = 1
    $$$ThrowOnError(settings.%Save())
    do ##class(SourceControl.Git.API).BaselineProductions()
    do ##class(SourceControl.Git.Utils).RunGitCommand("add",,,".")
    do ##class(SourceControl.Git.Utils).RunGitCommand("commit",,,"-m","decomposing production from unit test")
    do $$$AssertTrue(##class(SourceControl.Git.Utils).IsInSourceControl("UnitTest.SampleProduction||ProductionSettings-UnitTest.SampleProduction.PTD"))
    do $$$AssertTrue(##class(SourceControl.Git.Utils).IsInSourceControl("UnitTest.SampleProduction||Settings-a|Ens.Activity.Operation.Local.PTD"))
    do $$$AssertNotTrue(##class(SourceControl.Git.Utils).IsInSourceControl(..#ProductionName_".cls"))

    set settings.decomposeProductions = 0
    $$$ThrowOnError(settings.%Save())
    do ##class(SourceControl.Git.API).BaselineProductions()
    do ##class(SourceControl.Git.Utils).RunGitCommand("add",,,".")
    do ##class(SourceControl.Git.Utils).RunGitCommand("commit",,,"-m","recomposing production from unit test")
    do $$$AssertNotTrue(##class(SourceControl.Git.Utils).IsInSourceControl("UnitTest.SampleProduction||ProductionSettings-UnitTest.SampleProduction.PTD"))
    do $$$AssertNotTrue(##class(SourceControl.Git.Utils).IsInSourceControl("UnitTest.SampleProduction||Settings-a|Ens.Activity.Operation.Local.PTD"))
    do $$$AssertTrue(##class(SourceControl.Git.Utils).IsInSourceControl(..#ProductionName_".cls"))
}

Method TestEditProduction()
{
    new %session, %request, %SourceControl
    set %session = ##class(%CSP.Session).%New("dummysession")
    set %request = ##class(%CSP.Request).%New()
    set %request.Data("pageclass",1) = "EnsPortal.dummy"
    do $System.OBJ.Delete(..#ProductionName)
    $$$ThrowOnError(##class(SourceControl.Git.Utils).NewBranch("branch1"))
    $$$ThrowOnError(##class(SourceControl.Git.Production).CreateProduction(..#ProductionName))
	do ##class(%Studio.SourceControl.Interface).SourceControlCreate()
    $$$ThrowOnError(##class(SourceControl.Git.Utils).AddToSourceControl(..#ProductionName_".cls"))

    do $$$LogMessage("with production decomposition enabled, the production class should not be in source control.")
    do $$$AssertNotTrue(##class(SourceControl.Git.Utils).IsInSourceControl(..#ProductionName_".cls"))
    do $$$LogMessage("initial creation of a production should export production settings and add to source control.")
    $$$ThrowOnError(%SourceControl.OnBeforeSave(..#ProductionName_".cls"))
    $$$ThrowOnError(%SourceControl.OnAfterSave(..#ProductionName_".cls"))
    do $$$AssertTrue(##class(SourceControl.Git.Utils).IsInSourceControl("UnitTest.SampleProduction||ProductionSettings-UnitTest.SampleProduction.PTD"))

    do $$$LogMessage("adding a production item should add it to source control")
    $$$ThrowOnError(%SourceControl.OnBeforeSave(..#ProductionName_".cls"))
    do ..ReplaceProductionDefinition("ProductionDefinition1")
    $$$ThrowOnError(%SourceControl.OnAfterSave(..#ProductionName_".cls"))
    do $$$AssertTrue(##class(SourceControl.Git.Utils).IsInSourceControl("UnitTest.SampleProduction||Settings-a|Ens.Activity.Operation.Local.PTD"))

    do $$$LogMessage("committing changes to production settings")
    do ##class(SourceControl.Git.Utils).RunGitCommand("add",,,".")
    do ##class(SourceControl.Git.Utils).Commit("UnitTest.SampleProduction||ProductionSettings-UnitTest.SampleProduction.PTD")
    do ##class(SourceControl.Git.Utils).Commit("UnitTest.SampleProduction||Settings-a|Ens.Activity.Operation.Local.PTD")

    do $$$LogMessage("switching to a new branch")
    $$$ThrowOnError(##class(SourceControl.Git.Utils).NewBranch("branch2"))

    do $$$LogMessage("adding a new item and modifying an existing item")
    $$$ThrowOnError(%SourceControl.OnBeforeSave(..#ProductionName_".cls"))
    do ..ReplaceProductionDefinition("ProductionDefinition2")
    $$$ThrowOnError(%SourceControl.OnAfterSave(..#ProductionName_".cls"))
    set production = ##class(Ens.Config.Production).%OpenId(..#ProductionName)
    set production.Items.GetAt(1).Settings.GetAt(1).Value = 71
    $$$ThrowOnError(%SourceControl.OnBeforeSave(..#ProductionName_".cls"))
    do ..ReplaceProductionDefinition("ProductionDefinition3")
    $$$ThrowOnError(%SourceControl.OnAfterSave(..#ProductionName_".cls"))
    do $$$AssertTrue(##class(SourceControl.Git.Utils).IsInSourceControl("UnitTest.SampleProduction||Settings-b|EnsLib.SOAP.GenericOperation.PTD"))
    do ##class(SourceControl.Git.Utils).RunGitCommand("add",,,".")
    do ##class(SourceControl.Git.Utils).Commit("UnitTest.SampleProduction||Settings-a|Ens.Activity.Operation.Local.PTD")
    do ##class(SourceControl.Git.Utils).Commit("UnitTest.SampleProduction||Settings-b|EnsLib.SOAP.GenericOperation.PTD")
    $$$ThrowOnError(production.%Reload())
    do $$$AssertEquals(production.Items.Count(), 2)
    do $$$AssertEquals(production.Items.GetAt(1).Settings.GetAt(1).Name, "RecordStatsInterval")
    do $$$AssertEquals(production.Items.GetAt(1).Settings.GetAt(1).Value, 71)

    do $$$LogMessage("switching back to the original branch should modify and delete items")
    $$$ThrowOnError(##class(SourceControl.Git.Utils).SwitchBranch("branch1"))
    $$$ThrowOnError(production.%Reload())
    do $$$AssertEquals(production.Items.Count(), 1)
    do $$$AssertEquals(production.Items.GetAt(1).Settings.GetAt(1).Name, "RecordStatsInterval")
    do $$$AssertEquals(production.Items.GetAt(1).Settings.GetAt(1).Value, 61)
}

ClassMethod ReplaceProductionDefinition(pXDataName)
{
    new %SourceControl
    set productionClass = ##class(%Dictionary.ClassDefinition).%OpenId(..#ProductionName)
    do productionClass.XDatas.Clear()
	set productionXData = ##class(%Dictionary.XDataDefinition).%New()
    set xdata = ##class(%Dictionary.XDataDefinition).IDKEYOpen($classname(),pXDataName,,.st)
    $$$ThrowOnError(st)
    set productionXData = xdata.%ConstructClone(1)
	set productionXData.Name = "ProductionDefinition"
	set st = productionClass.XDatas.Insert(productionXData)
    $$$ThrowOnError(st)
    set st = productionClass.%Save()
    $$$ThrowOnError(st)
    set st = $System.OBJ.Compile(..#ProductionName)
    $$$ThrowOnError(st)
    set st = ##class(Ens.Production).Update()
    $$$ThrowOnError(st)
}

XData ProductionDefinition1
{
<Production Name="UnitTest.SampleProduction" LogGeneralTraceEvents="false">
  <Item Name="a" Category="" ClassName="Ens.Activity.Operation.Local" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="RecordStatsInterval">61</Setting>
  </Item>
</Production>
}

/// adds item b
XData ProductionDefinition2
{
<Production Name="UnitTest.SampleProduction" LogGeneralTraceEvents="false">
  <Item Name="a" Category="" ClassName="Ens.Activity.Operation.Local" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="RecordStatsInterval">61</Setting>
  </Item>
  <Item Name="b" Category="" ClassName="EnsLib.SOAP.GenericOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="HTTPServer"><![CDATA[<something that must be escaped>]]></Setting>
  </Item>
</Production>
}

/// modifies a setting for item a
XData ProductionDefinition3
{
<Production Name="UnitTest.SampleProduction" LogGeneralTraceEvents="false">
  <Item Name="a" Category="" ClassName="Ens.Activity.Operation.Local" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="RecordStatsInterval">71</Setting>
  </Item>
  <Item Name="b" Category="" ClassName="EnsLib.SOAP.GenericOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="HTTPServer"><![CDATA[<something that must be escaped>]]></Setting>
  </Item>
</Production>
}

Method OnBeforeAllTests() As %Status
{
	merge ..SourceControlGlobal = ^SYS("SourceControl")
    return $$$OK
}

Method OnBeforeOneTest() As %Status
{
	kill ^SYS("SourceControl")
	do ##class(%Studio.SourceControl.Interface).SourceControlClassSet("SourceControl.Git.Extension")
    set settings = ##class(SourceControl.Git.Settings).%New()
    set settings.decomposeProductions = 1
	Set settings.namespaceTemp = ##class(%Library.File).TempFilename()_"dir"
	Set settings.Mappings("PTD","*")="ptd/"
    $$$ThrowOnError(settings.%Save())
    // using work queue manager ensures proper OS user context/file ownership
    set workMgr = $System.WorkMgr.%New("")
    $$$ThrowOnError(workMgr.Queue("##class(SourceControl.Git.Utils).Init"))
    $$$ThrowOnError(workMgr.WaitForComplete())
	quit $$$OK
}

Method %OnClose() As %Status
{
	do ##class(%Studio.SourceControl.Interface).SourceControlClassSet(..InitialExtension)
	kill ^SYS("SourceControl")
	merge ^SYS("SourceControl") = ..SourceControlGlobal
    do $System.OBJ.Delete(..#ProductionName)
	quit $$$OK
}

}
