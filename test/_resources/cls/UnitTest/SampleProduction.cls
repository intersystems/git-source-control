Class UnitTest.SampleProduction Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="UnitTest.SampleProduction" LogGeneralTraceEvents="false">
  <Item Name="a" Category="" ClassName="Ens.Activity.Operation.Local" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="RecordStatsInterval">60</Setting>
  </Item>
  <Item Name="b" Category="" ClassName="Ens.Activity.Operation.Local" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="RecordStatsInterval">61</Setting>
  </Item>
</Production>
}

}
