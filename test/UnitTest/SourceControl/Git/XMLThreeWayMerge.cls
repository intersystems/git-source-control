Class UnitTest.SourceControl.Git.XMLThreeWayMerge Extends %UnitTest.TestCase
{

Method TestMerge()
{
    Set base = ..UtilXDataToDocument("Base")
    Set ours = ..UtilXDataToDocument("Ours")
    Set theirs = ..UtilXDataToDocument("Theirs")
    Set expectedResolve = ..UtilXDataToDocument("Resolved")

    Do ##class(SourceControl.Git.Util.ProductionConflictResolver).
}

Method UtilXDataToDocument(xDataName As %String) As %XML.Document
{
    Set xdata = ##class(%Dictionary.XDataDefinition).IDKEYOpen($classname(),xDataName,,.sc)
    $$$ThrowOnError(sc)
    Set reader = ##class(%XML.Reader).%New()
    $$$ThrowOnError(reader.OpenStream(xdata.Implementation))
    Quit reader.Document
}

XData Base
{
<Production Name="HCC.Connect.Production" LogGeneralTraceEvents="false">
  <Description>Health Connect Cloud Base Production</Description>
  <ActorPoolSize>1</ActorPoolSize>
  <Item Name="FeatureH" Category="" ClassName="Ens.Activity.Operation.REST" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="HTTPPort">12345</Setting>
    <Setting Target="Adapter" Name="HTTPServer">localhost</Setting>
  </Item>
  <Item Name="Baz" Category="" ClassName="EnsLib.DICOM.Duplex.TCP" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Demo5" Category="" ClassName="EnsLib.AmazonCloudWatch.MetricAlarmOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
</Production>
}

XData Ours
{
<Production Name="HCC.Connect.Production" LogGeneralTraceEvents="false">
  <Description>Health Connect Cloud Base Production Ours</Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="FeatureH" Category="" ClassName="Ens.Activity.Operation.REST" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="HTTPPort">12346</Setting>
    <Setting Target="Adapter" Name="HTTPServer">localhost</Setting>
  </Item>
  <Item Name="Baz" Category="" ClassName="EnsLib.DICOM.Duplex.TCP" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Demo5" Category="" ClassName="EnsLib.AmazonCloudWatch.MetricAlarmOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
</Production>
}

XData Theirs
{
<Production Name="HCC.Connect.Production" LogGeneralTraceEvents="false">
  <Description>Health Connect Cloud Base Production</Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="FeatureH" Category="" ClassName="Ens.Activity.Operation.REST" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="HTTPPort">12345</Setting>
    <Setting Target="Adapter" Name="HTTPServer">example.com</Setting>
  </Item>
  <Item Name="Baz" Category="" ClassName="EnsLib.DICOM.Duplex.TCP" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Demo7" Category="" ClassName="EnsLib.AmazonCloudWatch.MetricAlarmOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Demo8" Category="" ClassName="EnsLib.AmazonCloudWatch.MetricAlarmOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
</Production>
}

XData Resolved
{
<Production Name="HCC.Connect.Production" LogGeneralTraceEvents="false">
  <Description>Health Connect Cloud Base Production Ours</Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="FeatureH" Category="" ClassName="Ens.Activity.Operation.REST" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="HTTPPort">12346</Setting>
    <Setting Target="Adapter" Name="HTTPServer">example.com</Setting>
  </Item>
  <Item Name="Baz" Category="" ClassName="EnsLib.DICOM.Duplex.TCP" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Demo5" Category="" ClassName="EnsLib.AmazonCloudWatch.MetricAlarmOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Demo7" Category="" ClassName="EnsLib.AmazonCloudWatch.MetricAlarmOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Demo8" Category="" ClassName="EnsLib.AmazonCloudWatch.MetricAlarmOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
</Production>
}

}
