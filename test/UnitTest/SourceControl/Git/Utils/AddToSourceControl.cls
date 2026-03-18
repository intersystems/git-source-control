Import SourceControl.Git

Class UnitTest.SourceControl.Git.Utils.AddToSourceControl Extends UnitTest.SourceControl.Git.AbstractTest
{

Property RoutineMappingCreated As %Boolean [ InitialExpression = 0 ];

Property PackageMappingCreated As %Boolean [ InitialExpression = 0 ];

Method %OnNew(initvalue) As %Status
{
	Set sc = ##super(initvalue)
	If $$$ISERR(sc) Quit sc
	Set settings = ##class(SourceControl.Git.Settings).%New()
	Set settings.Mappings("MAC","*") = "rtn/"
	Do settings.%Save()
	Quit $$$OK
}

Method %OnClose() As %Status [ Private, ServerOnly = 1 ]
{
	// Clean up routines
	if ##class(%Routine).Exists("%gitunittestroutine.mac") {
		do ##class(%Routine).Delete("%gitunittestroutine.mac")
	}
	if ##class(%Routine).Exists("gitunittestroutine.mac") {
		do ##class(%Routine).Delete("gitunittestroutine.mac")
	}
	// Clean up classes
	if $$$defClassDefined("%gitunittest.TestClass") {
		do $system.OBJ.Delete("%gitunittest.TestClass.CLS", "-d")
	}
	if $$$defClassDefined("gitunittest.TestClass") {
		do $system.OBJ.Delete("gitunittest.TestClass.CLS", "-d")
	}
	// Clean up mappings
	if ..RoutineMappingCreated {
		do ..DeleteRoutineMapping("%gitunittest*")
	}
	if ..PackageMappingCreated {
		do ..DeletePackageMapping("%gitunittest")
	}
	Quit ##super()
}

/// Returns the name of the default routine database for this namespace.
Method GetDefaultDBName() As %String
{
	set defaultDB = ##class(%SYS.Namespace).GetRoutineDest($namespace, "gitunittestroutine.mac")
	quit ##class(%File).GetDirectoryPiece(defaultDB, ##class(%File).GetDirectoryLength(defaultDB))
}

/// Creates a routine mapping in %SYS so that routines matching the given pattern
/// resolve to the current namespace's default routine database.
Method CreateRoutineMapping(pattern As %String) As %Status
{
	set ns = $namespace
	set defaultDBName = ..GetDefaultDBName()

	new $namespace
	set $namespace = "%SYS"
	set props("Database") = defaultDBName
	set sc = ##class(Config.MapRoutines).Create(ns, pattern, .props)
	quit sc
}

/// Creates a package mapping in %SYS so that classes in the given package
/// resolve to the current namespace's default routine database.
Method CreatePackageMapping(package As %String) As %Status
{
	set ns = $namespace
	set defaultDBName = ..GetDefaultDBName()

	new $namespace
	set $namespace = "%SYS"
	set props("Database") = defaultDBName
	set sc = ##class(Config.MapPackages).Create(ns, package, .props)
	quit sc
}

/// Deletes a routine mapping from %SYS for the given pattern.
ClassMethod DeleteRoutineMapping(pattern As %String) As %Status
{
	set ns = $namespace
	new $namespace
	set $namespace = "%SYS"
	quit ##class(Config.MapRoutines).Delete(ns, pattern)
}

/// Deletes a package mapping from %SYS for the given package.
ClassMethod DeletePackageMapping(package As %String) As %Status
{
	set ns = $namespace
	new $namespace
	set $namespace = "%SYS"
	quit ##class(Config.MapPackages).Delete(ns, package)
}

Method TestNonPercentRoutine()
{
	set internalName = "gitunittestroutine.mac"

	set r = ##class(%Routine).%New(internalName)
	do r.WriteLine(" write ""hello"",!")
	$$$ThrowOnError(r.Save())

	// Verify FullExternalName returns a non-empty path
	set fullName = ##class(Utils).FullExternalName(internalName)
	do $$$AssertNotEquals(fullName, "")

	// Add to source control and verify it exported to the file system
	do $$$AssertStatusOK(##class(Utils).AddToSourceControl(internalName))
	do $$$AssertTrue(##class(%File).Exists(fullName), "non-% routine file should exist on disk after AddToSourceControl")
}

Method TestPercentRoutine()
{
	set internalName = "%gitunittestroutine.mac"

	$$$ThrowOnError(..CreateRoutineMapping("%gitunittest*"))
	set ..RoutineMappingCreated = 1

	// Create a routine named %gitunittestroutine.mac
	set r = ##class(%Routine).%New(internalName)
	do r.WriteLine(" write ""hello"",!")
	$$$ThrowOnError(r.Save())


	// Verify FullExternalName returns a non-empty path
	set fullName = ##class(Utils).FullExternalName(internalName)
	do $$$AssertNotEquals(fullName, "")

	// Add to source control and verify it exported to the file system
	do $$$AssertStatusOK(##class(Utils).AddToSourceControl(internalName))
	do $$$AssertTrue(##class(%File).Exists(fullName), "% routine file should exist on disk after AddToSourceControl")
}

Method TestNonPercentClass()
{
	set internalName = "gitunittest.TestClass.CLS"

	set classDef = ##class(%Dictionary.ClassDefinition).%New()
	set classDef.Name = "gitunittest.TestClass"
	$$$ThrowOnError(classDef.%Save())

	set fullName = ##class(Utils).FullExternalName(internalName)
	do $$$AssertNotEquals(fullName, "", "FullExternalName should return a path for non-% class")

	do $$$AssertStatusOK(##class(Utils).AddToSourceControl(internalName))
	do $$$AssertTrue(##class(%File).Exists(fullName), "non-% class file should exist on disk after AddToSourceControl")
}

Method TestPercentClass()
{
	set internalName = "%gitunittest.TestClass.CLS"

	$$$ThrowOnError(..CreatePackageMapping("%gitunittest"))
	set ..PackageMappingCreated = 1

	set classDef = ##class(%Dictionary.ClassDefinition).%New()
	set classDef.Name = "%gitunittest.TestClass"
	$$$ThrowOnError(classDef.%Save())
	$$$ThrowOnError($system.OBJ.Compile("%gitunittest.TestClass", "ck-d"))

	set fullName = ##class(Utils).FullExternalName(internalName)
	do $$$AssertNotEquals(fullName, "", "FullExternalName should return a path for % class")

	do $$$AssertStatusOK(##class(Utils).AddToSourceControl(internalName))
	do $$$AssertTrue(##class(%File).Exists(fullName), "% class file should exist on disk after AddToSourceControl")
}

}
