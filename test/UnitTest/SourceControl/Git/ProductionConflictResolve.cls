Class UnitTest.SourceControl.Git.ProductionConflictResolve Extends %UnitTest.TestCase
{

Method TestResolve()
{
    Set file = ##class(%Stream.FileCharacter).%New()
    Set file.RemoveOnClose = 1
    Set xdata = ##class(%Dictionary.XDataDefinition).IDKEYOpen($classname(),"SampleFile1",,.sc)
    While 'xdata.Data.AtEnd {
        Do file.WriteLine(xdata.Data.ReadLine())
    }
    $$$ThrowOnError(file.%Save())

    Set resolved = ##class(%Stream.FileCharacter).%New()
    Set resolved.RemoveOnClose = 1
    Set xdata = ##class(%Dictionary.XDataDefinition).IDKEYOpen($classname(),"ResolvedFile1",,.sc)
    While 'xdata.Data.AtEnd {
        Do resolved.WriteLine(xdata.Data.ReadLine())
    }
    $$$ThrowOnError(resolved.%Save())

    Do ##class(SourceControl.Git.Util.ProductionConflictResolver).ResolveStream(file)

    Do $$$AssertFilesSame(file.Filename,resolved.Filename)
}

XData SampleFile1 [ MimeType = text/plain ]
{
Class HCC.Connect.Production Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="HCC.Connect.Production" LogGeneralTraceEvents="false">
  <Description>Health Connect Cloud Base Production</Description>
  <ActorPoolSize>1</ActorPoolSize>
  <Item Name="Ens.Activity.Operation.Local" Category="" ClassName="Ens.Activity.Operation.Local" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Ens.Enterprise.MsgBankOperation" Category="" ClassName="Ens.Enterprise.MsgBankOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="Health Connect Cloud Message Bank" LogTraceEvents="false" Schedule="">
  <Setting Target="Adapter" Name="IPAddress">bank</Setting>
  </Item>
  <Item Name="FeatureA Service" Category="" ClassName="EnsLib.HL7.Service.FTPService" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="FeatureA Process" Category="" ClassName="EnsLib.HL7.MsgRouter.RoutingEngine" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="BusinessRuleName">HCC.Connect.FeatureAProcessRoutingRule</Setting>
  </Item>
  <Item Name="FeatureA Operation" Category="" ClassName="EnsLib.HL7.Operation.TCPOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="FeatureB" Category="" ClassName="EnsLib.HL7.Service.TCPService" PoolSize="1" Enabled="false" Foreground="false" Comment="Comment" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="FeatureBProcess" Category="" ClassName="EnsLib.HL7.MsgRouter.RoutingEngine" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="BusinessRuleName">HCC.Connect.FeatureBProcessRoutingRule</Setting>
  </Item>
  <Item Name="FeatureB Operation" Category="" ClassName="EnsLib.HL7.Operation.FileOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="Comment 12" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="FeatureC Operation" Category="" ClassName="EnsLib.HL7.Operation.TCPOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="IPAddress">127.0.0.1</Setting>
    <Setting Target="Adapter" Name="Port">8080</Setting>
  </Item>
  <Item Name="FeatureG" Category="" ClassName="EnsLib.HL7.Service.TCPService" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="FeatureD" Category="" ClassName="EnsLib.FTP.PassthroughService" PoolSize="1" Enabled="false" Foreground="false" Comment="." LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="FeatureE" Category="" ClassName="EnsLib.EDI.X12.Operation.TCPOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="IPAddress">1.4.3.5</Setting>
  </Item>
  <Item Name="FeatureH" Category="" ClassName="Ens.Activity.Operation.REST" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="HTTPPort">12345</Setting>
    <Setting Target="Adapter" Name="HTTPServer">localhost</Setting>
  </Item>
  <Item Name="Baz" Category="" ClassName="EnsLib.DICOM.Duplex.TCP" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
<<<<<<< HEAD
  <Item Name="Demo7" Category="" ClassName="EnsLib.CloudStorage.BusinessOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
=======
  <Item Name="Demo5" Category="" ClassName="EnsLib.AmazonCloudWatch.MetricAlarmOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
>>>>>>> 607d1f6 (modified src/HCC/Connect/Production.cls add Demo5)
  </Item>
</Production>
}

}
}

XData ResolvedFile1 [ MimeType = text/plain ]
{
Class HCC.Connect.Production Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="HCC.Connect.Production" LogGeneralTraceEvents="false">
  <Description>Health Connect Cloud Base Production</Description>
  <ActorPoolSize>1</ActorPoolSize>
  <Item Name="Ens.Activity.Operation.Local" Category="" ClassName="Ens.Activity.Operation.Local" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Ens.Enterprise.MsgBankOperation" Category="" ClassName="Ens.Enterprise.MsgBankOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="Health Connect Cloud Message Bank" LogTraceEvents="false" Schedule="">
  <Setting Target="Adapter" Name="IPAddress">bank</Setting>
  </Item>
  <Item Name="FeatureA Service" Category="" ClassName="EnsLib.HL7.Service.FTPService" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="FeatureA Process" Category="" ClassName="EnsLib.HL7.MsgRouter.RoutingEngine" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="BusinessRuleName">HCC.Connect.FeatureAProcessRoutingRule</Setting>
  </Item>
  <Item Name="FeatureA Operation" Category="" ClassName="EnsLib.HL7.Operation.TCPOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="FeatureB" Category="" ClassName="EnsLib.HL7.Service.TCPService" PoolSize="1" Enabled="false" Foreground="false" Comment="Comment" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="FeatureBProcess" Category="" ClassName="EnsLib.HL7.MsgRouter.RoutingEngine" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="BusinessRuleName">HCC.Connect.FeatureBProcessRoutingRule</Setting>
  </Item>
  <Item Name="FeatureB Operation" Category="" ClassName="EnsLib.HL7.Operation.FileOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="Comment 12" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="FeatureC Operation" Category="" ClassName="EnsLib.HL7.Operation.TCPOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="IPAddress">127.0.0.1</Setting>
    <Setting Target="Adapter" Name="Port">8080</Setting>
  </Item>
  <Item Name="FeatureG" Category="" ClassName="EnsLib.HL7.Service.TCPService" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="FeatureD" Category="" ClassName="EnsLib.FTP.PassthroughService" PoolSize="1" Enabled="false" Foreground="false" Comment="." LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="FeatureE" Category="" ClassName="EnsLib.EDI.X12.Operation.TCPOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="IPAddress">1.4.3.5</Setting>
  </Item>
  <Item Name="FeatureH" Category="" ClassName="Ens.Activity.Operation.REST" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="HTTPPort">12345</Setting>
    <Setting Target="Adapter" Name="HTTPServer">localhost</Setting>
  </Item>
  <Item Name="Baz" Category="" ClassName="EnsLib.DICOM.Duplex.TCP" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Demo7" Category="" ClassName="EnsLib.CloudStorage.BusinessOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Demo5" Category="" ClassName="EnsLib.AmazonCloudWatch.MetricAlarmOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
</Production>
}

}
}

}
