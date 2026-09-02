/// Regression test for https://github.com/intersystems/git-source-control/issues/997 - "Embedded Git
/// deletes itself on import". Embedded Git installed in one namespace and mapped into the rest of the
/// instance with <method>SourceControl.Git.API.MapEverywhere</method> has no IPM module record in the
/// other namespaces, so Import All there used to see its classes as unowned and delete them - out of
/// the database they are mapped from, breaking the installation instance-wide.
Class UnitTest.SourceControl.Git.MappedNamespace Extends UnitTest.SourceControl.Git.AbstractTest
{

/// Namespace and database created by this test and deleted again afterwards.
Parameter ScratchNamespace As STRING = "GSCUNITTESTMAP";

/// The item Embedded Git deleted out from under itself in #997.
Parameter MappedItem As STRING = "SourceControl.Git.Utils.CLS";

Method TestImportAllInMappedNamespace()
{
	set homePackage = ##class(SourceControl.Git.PackageManagerContext).ForInternalName(..#MappedItem).HomePackageName
	do $$$AssertNotEquals(homePackage, "", "Embedded Git belongs to an IPM package in "_$namespace)

	kill result
	set error = $$$NULLOREF
	do ..RecordMapEverywhereMappings(.mappings)
	try {
		$$$ThrowOnError(..CreateScratchNamespace())
		$$$ThrowOnError(##class(SourceControl.Git.API).MapEverywhere())
		do ..ImportAllInScratchNamespace(.result)
	} catch e {
		set error = e
	}
	set teardown = ..RemoveAddedMappings(.mappings)
	set teardown = $$$ADDSC(teardown, ..DeleteScratchNamespace())

	// assertions run after the switch back, so that they are recorded in this namespace
	if $isobject(error) {
		do $$$AssertStatusOK(error.AsStatus(), "setup and import in "_..#ScratchNamespace)
	}

	// the conditions that made #997 possible: the item is mapped in from the namespace Embedded Git
	// is installed in, and has no module of its own where Import All is running
	do $$$AssertEquals($get(result("sourceNamespace")), $namespace)
	do $$$AssertNotTrue($get(result("localPackage")))
	do $$$AssertEquals($get(result("homePackage")), homePackage)
	do $$$AssertNotTrue(##class(%File).Exists($get(result("fullExternalName"))))

	// ...and Import All leaves it alone anyway
	do $$$AssertTrue($get(result("importRan")), "Import All ran in "_..#ScratchNamespace)
	do $$$AssertStatusOK($get(result("importStatus"), $$$OK))
	do $$$AssertTrue($get(result("survived")))
	do $$$AssertTrue(##class(%Dictionary.ClassDefinition).%ExistsId($piece(..#MappedItem, ".", 1, *-1)))

	do $$$AssertStatusOK(teardown, "cleaned up "_..#ScratchNamespace)
}

/// Configures Embedded Git in the scratch namespace and runs Import All there with a stale timestamp
/// for <parameter>MappedItem</parameter> and no file for it on disk - the state that triggered #997.
/// Observations are returned in <var>result</var> rather than asserted, because %UnitTest records
/// assertions in the namespace they are made in.
Method ImportAllInScratchNamespace(Output result) [ Private ]
{
	kill result
	new $namespace
	set $namespace = ..#ScratchNamespace

	set repository = ##class(%File).NormalizeDirectory(##class(%File).TempFilename()_"dir")
	do ##class(%File).CreateDirectoryChain(repository)
	kill ^SYS("SourceControl")
	set settings = ##class(SourceControl.Git.Settings).%New()
	set settings.namespaceTemp = repository
	set settings.Mappings("CLS","*") = "cls/"
	$$$ThrowOnError(settings.%Save())
	do ##class(%Studio.SourceControl.Interface).SourceControlClassSet("SourceControl.Git.Extension")

	// Import All from the web UI runs with no current document, so the ambient context is empty
	set result("ambientPackage") = ##class(SourceControl.Git.PackageManagerContext).%Get().HomePackageName
	set result("sourceNamespace") = ##class(SourceControl.Git.PackageManagerContext).SourceNamespace(..#MappedItem)
	set context = ##class(SourceControl.Git.PackageManagerContext).ForInternalName(..#MappedItem)
	set result("localPackage") = $isobject(context.Package)
	set result("homePackage") = context.HomePackageName
	// reading the above made the mapped item the current document; put the context back the way
	// Import All would have found it
	set context.InternalName = ""

	$$$ThrowOnError(##class(SourceControl.Git.Utils).UpdateRoutineTSH(..#MappedItem))
	set result("fullExternalName") = ##class(SourceControl.Git.Utils).FullExternalName(..#MappedItem)

	// Don't import at all if the context says Import All would delete Embedded Git out of the
	// namespace it is installed in - the observations above report why.
	if (result("ambientPackage") = "") && (result("homePackage") '= "") {
		set result("importRan") = 1
		set result("importStatus") = ##class(SourceControl.Git.API).ImportAll(1)
		set result("survived") = ##class(%Dictionary.ClassDefinition).%ExistsId($piece(..#MappedItem, ".", 1, *-1))
	}

	kill ^SYS("SourceControl")
	do ##class(%File).RemoveDirectoryTree(repository)
}

/// Creates the scratch database and namespace, removing any left over from an earlier run.
ClassMethod CreateScratchNamespace() As %Status [ Private ]
{
	new $namespace
	$$$QuitOnError(..DeleteScratchNamespace())
	set $namespace = "%SYS"
	set directory = ##class(%File).NormalizeDirectory(..#ScratchNamespace, $system.Util.ManagerDirectory())
	if '##class(%File).CreateDirectoryChain(directory, .return) {
		quit $$$ERROR($$$GeneralError, "failed to create directory "_directory_": "_return)
	}
	$$$QuitOnError(##class(SYS.Database).CreateDatabase(directory))
	kill properties
	set properties("Directory") = directory
	$$$QuitOnError(##class(Config.Databases).Create(..#ScratchNamespace, .properties))
	kill properties
	set properties("Globals") = ..#ScratchNamespace
	set properties("Routines") = ..#ScratchNamespace
	quit ##class(Config.Namespaces).Create(..#ScratchNamespace, .properties)
}

/// Deletes the scratch namespace, its database, and the database's files.
ClassMethod DeleteScratchNamespace() As %Status [ Private ]
{
	new $namespace
	set sc = $$$OK
	set $namespace = "%SYS"
	if ##class(Config.Namespaces).Exists(..#ScratchNamespace) {
		set sc = $$$ADDSC(sc, ##class(Config.Namespaces).Delete(..#ScratchNamespace))
	}
	set directory = ""
	if ##class(Config.Databases).Exists(..#ScratchNamespace) {
		set sc = $$$ADDSC(sc, ##class(Config.Databases).Get(..#ScratchNamespace, .properties))
		set directory = $get(properties("Directory"))
		set sc = $$$ADDSC(sc, ##class(Config.Databases).Delete(..#ScratchNamespace))
	}
	if (directory '= "") {
		do ##class(SYS.Database).DismountDatabase(directory)
		do ##class(%File).RemoveDirectoryTree(directory)
	}
	quit sc
}

/// Records which of the %ALL mappings <method>SourceControl.Git.API.MapEverywhere</method> makes are
/// already configured, so that only the ones this test adds are removed again.
ClassMethod RecordMapEverywhereMappings(Output mappings) [ Private ]
{
	new $namespace
	kill mappings
	set $namespace = "%SYS"
	set mappings("package", "SourceControl.Git") = ##class(Config.MapPackages).Exists("%ALL", "SourceControl.Git")
	set mappings("global", "IRIS.Msg") = ##class(Config.MapGlobals).Exists("%ALL", "IRIS.Msg")
	set mappings("global", "IRIS.Msg(""Studio"")") = ##class(Config.MapGlobals).Exists("%ALL", "IRIS.Msg(""Studio"")")
}

/// Removes the %ALL mappings that were not configured when <method>RecordMapEverywhereMappings</method>
/// last ran.
ClassMethod RemoveAddedMappings(ByRef mappings) As %Status [ Private ]
{
	new $namespace
	set sc = $$$OK
	set $namespace = "%SYS"
	set kind = ""
	for {
		set kind = $order(mappings(kind))
		quit:kind=""
		set name = ""
		for {
			set name = $order(mappings(kind, name), 1, existed)
			quit:name=""
			continue:existed
			if (kind = "package") {
				set sc = $$$ADDSC(sc, ##class(Config.MapPackages).Delete("%ALL", name))
			} else {
				set sc = $$$ADDSC(sc, ##class(Config.MapGlobals).Delete("%ALL", name))
			}
		}
	}
	quit sc
}

}
