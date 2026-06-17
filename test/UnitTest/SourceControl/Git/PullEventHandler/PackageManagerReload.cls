/// integration tests for the Package Manager Reload pull event handler
Class UnitTest.SourceControl.Git.PullEventHandler.PackageManagerReload Extends UnitTest.SourceControl.Git.AbstractTest
{

Method TestLoadUninstallsThenInstalls()
{
    set testModulePath = ##class(SourceControl.Git.PackageManagerContext).ForInternalName("git-source-control.zpm").Package.Root_"test/_resources/simplest-module"
    set pullEventHandler = ##class(SourceControl.Git.PullEventHandler.PackageManagerReload).%New()
    set pullEventHandler.LocalRoot = testModulePath
    // pull once to install simplest-module
    do $$$AssertStatusOK(pullEventHandler.OnPull())
    // pull again to verify uninstall + install
    do $$$AssertStatusOK(pullEventHandler.OnPull())
    set history = ##class(%IPM.General.History).GetHistory(,,2)
    do $$$AssertTrue(history.%Next())
    do $$$AssertEquals(history.Action,"load")
    do $$$AssertTrue(history.%Next())
    do $$$AssertEquals(history.Action,"uninstall")
    do $$$AssertEquals(history.CommandString,"uninstall simplest-module")
    zpm "uninstall simplest-module"
}

Method TestLoadUsesConfiguredFlags()
{
    set testModulePath = ##class(SourceControl.Git.PackageManagerContext).ForInternalName("git-source-control.zpm").Package.Root_"test/_resources/simplest-module"
    set initFlags = $get(@##class(SourceControl.Git.Utils).#Storage@("settings","IPM","loadFlags"))
    set flags = "-DNoMapping=1 -extra-pip-flags ""--timeout 30"""
    do ##class(SourceControl.Git.PullEventHandler.PackageManagerReload).ConfigureLoadFlags(flags)
    set pullEventHandler = ##class(SourceControl.Git.PullEventHandler.PackageManagerReload).%New()
    set pullEventHandler.LocalRoot = testModulePath
    do $$$AssertStatusOK(pullEventHandler.OnPull())
    set history = ##class(%IPM.General.History).GetHistory(,,2)
    do $$$AssertTrue(history.%Next())
    do $$$AssertEquals(history.Action,"load")
    do $$$AssertEquals(history.CommandString, "load "_testModulePath_" -DNoMapping=1 -extra-pip-flags ""--timeout 30""")
    zpm "uninstall simplest-module"
    do ##class(SourceControl.Git.PullEventHandler.PackageManagerReload).ConfigureLoadFlags(initFlags)
}

}
