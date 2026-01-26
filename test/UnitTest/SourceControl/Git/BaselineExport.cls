Class UnitTest.SourceControl.Git.BaselineExport Extends %UnitTest.TestCase
{

Parameter ProductionName = "UnitTest.BaselineExportProduction";

Method TestBaselineExport()
{
    // create a mac routine
	if '##class(%Routine).Exists("test.mac") {
		set r = ##class(%Routine).%New("test.mac")
		do r.WriteLine(" write 22,!")
		do r.Save()
		do r.Compile()
	}
    // create an inc routine
	if '##class(%Routine).Exists("test.inc") {
		set r = ##class(%Routine).%New("test.inc")
		do r.WriteLine(" ; test include routine")
		do r.Save()
		do r.Compile()
	}
    // create a class
    if '##class(%Dictionary.ClassDefinition).%OpenId("TestPkg.Class") {
        set class = ##class(%Dictionary.ClassDefinition).%New()
        set class.Name = "TestPkg.Class"
        $$$ThrowOnError(class.%Save())
        do $system.OBJ.Compile("TestPkg.Class")
    }
    do $$$AssertNotTrue(##class(SourceControl.Git.Utils).IsInSourceControl("test.mac"))
    do $$$AssertNotTrue(##class(SourceControl.Git.Utils).IsInSourceControl("test.inc"))
    do $$$AssertNotTrue(##class(SourceControl.Git.Utils).IsInSourceControl("TestPkg.Class.cls"))
    do $$$AssertStatusOK(##class(SourceControl.Git.API).BaselineExport())
    do $$$AssertTrue(##class(SourceControl.Git.Utils).IsInSourceControl("test.mac"))
    do $$$AssertTrue(##class(SourceControl.Git.Utils).IsInSourceControl("test.inc"))
    do $$$AssertTrue(##class(SourceControl.Git.Utils).IsInSourceControl("TestPkg.Class.cls"))
}

Method TestBaselineExportWithDecomposedProduction()
{
    do $System.OBJ.Delete(..#ProductionName)
    set settings = ##class(SourceControl.Git.Settings).%New()
    set settings.decomposeProductions = 1
    $$$ThrowOnError(settings.%Save())
    $$$ThrowOnError(##class(SourceControl.Git.Production).CreateProduction(..#ProductionName))
    do ..ReplaceProductionDefinition()
    do $$$AssertNotTrue(##class(SourceControl.Git.Utils).IsInSourceControl(..#ProductionName_".cls"))
    do $$$AssertNotTrue(##class(SourceControl.Git.Utils).IsInSourceControl(..#ProductionName_"||ProductionSettings-"_..#ProductionName_".PTD"))
    do $$$AssertNotTrue(##class(SourceControl.Git.Utils).IsInSourceControl(..#ProductionName_"||Settings-a|Ens.Activity.Operation.Local.PTD"))
    do $$$AssertStatusOK(##class(SourceControl.Git.API).BaselineExport())
    do $$$AssertTrue(##class(SourceControl.Git.Utils).IsInSourceControl(..#ProductionName_"||ProductionSettings-"_..#ProductionName_".PTD"))
    do $$$AssertTrue(##class(SourceControl.Git.Utils).IsInSourceControl(..#ProductionName_"||Settings-a|Ens.Activity.Operation.Local.PTD"))
}

Property InitialExtension As %String [ InitialExpression = {##class(%Studio.SourceControl.Interface).SourceControlClassGet()} ];

Property SourceControlGlobal [ MultiDimensional ];

ClassMethod ReplaceProductionDefinition()
{
    set productionClass = ##class(%Dictionary.ClassDefinition).%OpenId(..#ProductionName)
    do productionClass.XDatas.Clear()
    set productionXData = ##class(%Dictionary.XDataDefinition).%New()
    set xdata = ##class(%Dictionary.XDataDefinition).IDKEYOpen($classname(),"ProductionDefinition",,.st)
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

Method %OnNew(initvalue) As %Status
{
	Merge ..SourceControlGlobal = ^SYS("SourceControl")
	Kill ^SYS("SourceControl")
	Set settings = ##class(SourceControl.Git.Settings).%New()
	Set settings.namespaceTemp = ##class(%Library.File).TempFilename()_"dir"
	Set settings.Mappings("MAC","*")="rtn/"
	Set settings.Mappings("CLS","*")="cls/"
    Set settings.Mappings("PTD","*")="ptd/"
	Do settings.%Save()
	Do ##class(%Studio.SourceControl.Interface).SourceControlClassSet("SourceControl.Git.Extension")
	Quit ##super(initvalue)
}

Method %OnClose() As %Status [ Private, ServerOnly = 1 ]
{
	Do ##class(%Studio.SourceControl.Interface).SourceControlClassSet(..InitialExtension)
	Kill ^SYS("SourceControl")
	Merge ^SYS("SourceControl") = ..SourceControlGlobal
    Do $System.OBJ.Delete(..#ProductionName)
	Quit $$$OK
}

XData ProductionDefinition
{
<Production Name="UnitTest.BaselineExportProduction" LogGeneralTraceEvents="false">
  <Item Name="a" Category="" ClassName="Ens.Activity.Operation.Local" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="RecordStatsInterval">61</Setting>
  </Item>
</Production>
}

}
