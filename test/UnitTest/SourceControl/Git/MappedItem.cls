/// Tests that items mapped in from another database are left alone by Import All.
/// Deleting such an item removes it from the database it is mapped from, and so from every namespace that
/// maps it in - that is how Embedded Git, mapped instance-wide, deleted itself.
/// See https://github.com/intersystems/git-source-control/issues/997 .
Class UnitTest.SourceControl.Git.MappedItem Extends UnitTest.SourceControl.Git.AbstractTest
{

/// Package mapped in from the %SYS namespace's routine database for the duration of the test.
Parameter MappedPackage As STRING = "gitunittestmapped";

Parameter MappedClass As STRING = "gitunittestmapped.TestClass";

Property PackageMappingCreated As %Boolean [ InitialExpression = 0 ];

Method %OnNew(initvalue) As %Status
{
	$$$QuitOnError(##super(initvalue))
	// mapped items are read-only by default, which keeps them out of source control entirely;
	// this test needs the mapped class tracked so that Import All considers deleting it
	set settings = ##class(SourceControl.Git.Settings).%New()
	set settings.mappedItemsReadOnly = 0
	quit settings.%Save()
}

Method %OnClose() As %Status [ Private, ServerOnly = 1 ]
{
	// the class lives in the mapped database, so it has to go before the mapping that reaches it
	if $$$defClassDefined(..#MappedClass) {
		do $system.OBJ.Delete(..#MappedClass)
	}
	if ..PackageMappingCreated {
		do ..DeletePackageMapping(..#MappedPackage)
	}
	quit ##super()
}

Method TestMappedClassNotDeleted()
{
	set internalName = ..#MappedClass_".CLS"

	$$$ThrowOnError(..CreatePackageMapping(..#MappedPackage))
	set ..PackageMappingCreated = 1

	set classDef = ##class(%Dictionary.ClassDefinition).%New()
	set classDef.Name = ..#MappedClass
	$$$ThrowOnError(classDef.%Save())
	$$$ThrowOnError($system.OBJ.Compile(..#MappedClass, "ck"))

	// the class is stored in the %SYS namespace's database rather than this namespace's own
	do $$$AssertTrue(##class(%Library.RoutineMgr).IsMapped(internalName), internalName_" is mapped in from another database")

	do $$$AssertStatusOK(##class(SourceControl.Git.Utils).AddToSourceControl(internalName))
	set fullExternalName = ##class(SourceControl.Git.Utils).FullExternalName(internalName)
	do $$$AssertTrue(##class(%File).Exists(fullExternalName), "mapped class exported to "_fullExternalName)

	// the situation that triggered #997: the item is in source control, but has no file on disk
	do $$$AssertTrue(##class(%File).Delete(fullExternalName), "deleted "_fullExternalName)
	do $$$AssertStatusOK(##class(SourceControl.Git.API).ImportAll(1))

	do $$$AssertTrue($$$defClassDefined(..#MappedClass), ..#MappedClass_" still exists after Import All")
}

/// Creates a package mapping in %SYS so that classes in <var>package</var> are stored in the database
/// the %SYS namespace keeps its routines in, rather than this namespace's own.
Method CreatePackageMapping(package As %String) As %Status
{
	set ns = $namespace
	new $namespace
	set $namespace = "%SYS"
	$$$QuitOnError(##class(Config.Namespaces).Get("%SYS", .namespaceProps))
	set props("Database") = namespaceProps("Routines")
	quit ##class(Config.MapPackages).Create(ns, package, .props)
}

/// Deletes the package mapping for <var>package</var>.
ClassMethod DeletePackageMapping(package As %String) As %Status
{
	set ns = $namespace
	new $namespace
	set $namespace = "%SYS"
	quit ##class(Config.MapPackages).Delete(ns, package)
}

}
