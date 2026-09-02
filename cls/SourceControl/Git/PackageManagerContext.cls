Include %occStatus

Class SourceControl.Git.PackageManagerContext Extends SourceControl.Git.Util.Singleton
{

/// Everything this class reports is namespace-specific, so a process that visits more than one
/// namespace - as Embedded Git does when it is mapped instance-wide - needs one instance per namespace
/// rather than one shared instance holding whichever namespace's answers it saw first.
Parameter NAMESPACESCOPE As BOOLEAN = 1;

Property InternalName As %String;

Property IsInDefaultPackage As %Boolean [ InitialExpression = 0 ];

Property IsInGitEnabledPackage As %Boolean [ InitialExpression = 0 ];

/// Really is a %ZPM.PackageManager.Developer.Module / %IPM.Storage.Module
Property Package As %RegisteredObject [ InitialExpression = {$$$NULLOREF} ];

/// Name of the IPM package that owns <property>InternalName</property>, or "" if no package does.
/// <p>This is not always <property>Package</property>.Name: an item mapped in from another namespace
/// has no module record here, so <property>Package</property> reports it as unowned. That is how
/// Embedded Git came to delete its own mapped-in classes - see
/// https://github.com/intersystems/git-source-control/issues/997 . Only the name is established for
/// such items, deliberately: resolving <property>Package</property> would put this namespace in charge
/// of another namespace's repository.</p>
/// <p>An empty name only means "no package owns this" when
/// <property>HomePackageUnknown</property> is false.</p>
Property HomePackageName As %String;

/// Set when <property>InternalName</property> is mapped in from another database and the owning package
/// could not be determined - most often because the user running Embedded Git has no privileges on the
/// namespace the item is mapped from, or on the databases behind it.
/// <p>Such an item must be treated as belonging to something else rather than as unowned: a user can
/// have enough privileges to delete a mapped-in item and not enough to find out who owns it, which is
/// how https://github.com/intersystems/git-source-control/issues/997 destroyed an installation.</p>
Property HomePackageUnknown As %Boolean [ InitialExpression = 0 ];

/// Really is a %ZPM.PackageManager.Developer.ResourceReference / %IPM.Storage.ResourceReference
Property ResourceReference As %RegisteredObject [ InitialExpression = {$$$NULLOREF} ];

Method InternalNameSet(InternalName As %String = "") As %Status
{
    set InternalName = ##class(SourceControl.Git.Utils).NormalizeInternalName(InternalName)
    if (InternalName '= i%InternalName) {
        set i%InternalName = InternalName
        set resourceReference = $$$NULLOREF
        set ..HomePackageUnknown = 0
        if (InternalName = ##class(SourceControl.Git.Settings.Document).#INTERNALNAME) {
            // Embedded Git settings document is never in an IPM context
            set ..Package = $$$NULLOREF
            set ..HomePackageName = ""
        } else {
            set sourceNamespace = ..SourceNamespace(InternalName, .resolved)
            if 'resolved {
                // mapped in from a database that could not be traced back to a namespace
                set ..Package = $$$NULLOREF
                set ..HomePackageName = ""
                set ..HomePackageUnknown = 1
            } elseif (sourceNamespace '= "") {
                set ..Package = $$$NULLOREF
                set ..HomePackageName = ..FindHomePackageName(InternalName, .resolved)
                set ..HomePackageUnknown = 'resolved
            } else {
                set ..Package = ..FindHomeModule(InternalName, .resourceReference)
                set ..HomePackageName = $select($isobject(..Package):..Package.Name, 1:"")
            }
        }
        set ..ResourceReference = resourceReference
        set ..IsInGitEnabledPackage = $isobject(..Package) && ##class(%Library.File).Exists(##class(%Library.File).NormalizeFilename(".git",..Package.Root))
        set ..IsInDefaultPackage = $isobject(..Package) && (##class(%Library.File).NormalizeDirectory(..Package.Root) = ##class(%Library.File).NormalizeDirectory(##class(SourceControl.Git.Utils).DefaultTempFolder()))
    }
    quit $$$OK
}

ClassMethod ForInternalName(InternalName As %String = "") As SourceControl.Git.PackageManagerContext
{
    set instance = ..%Get()
    set instance.InternalName = InternalName
    set InternalName = instance.InternalName
    quit instance
}

/// Returns the module that owns <var>internalName</var> in the current namespace, or $$$NULLOREF if no
/// module does or IPM is not enabled here.
ClassMethod FindHomeModule(internalName As %String, Output resourceReference As %RegisteredObject) As %RegisteredObject [ Internal, Private ]
{
    set resourceReference = $$$NULLOREF
    if $$$comClassDefined("%IPM.ExtensionBase.Utils") {
        quit ##class(%IPM.ExtensionBase.Utils).FindHomeModule(internalName,,.resourceReference)
    }
    if $$$comClassDefined("%ZPM.PackageManager.Developer.Extension.Utils") {
        quit ##class(%ZPM.PackageManager.Developer.Extension.Utils).FindHomeModule(internalName,,.resourceReference)
    }
    quit $$$NULLOREF
}

/// Returns the name of the IPM package that owns <var>internalName</var>, looking in the namespace the
/// item is mapped from, or "" if no package does. <var>resolved</var> is false if the lookup could not
/// be made at all, in which case the empty name says nothing about ownership.
/// <p>Only the name is returned because a swizzled %IPM.Storage.Module carries relationships that would
/// resolve against the wrong globals once $namespace is restored.</p>
ClassMethod FindHomePackageName(internalName As %String = "", Output resolved As %Boolean) As %String [ Internal ]
{
    set resolved = 1
    set packageName = ""
    new $namespace
    try {
        set sourceNamespace = ..SourceNamespace(internalName, .resolved)
        if resolved {
            set:sourceNamespace'="" $namespace = sourceNamespace
            set package = ..FindHomeModule(internalName)
            set packageName = $select($isobject(package):package.Name, 1:"")
            // Release the module before $namespace is restored.
            set package = $$$NULLOREF
        }
    } catch e {
        // <PROTECT> if the user may not enter the namespace the item is mapped from, or may not read
        // the database IPM's own data lives in there
        set resolved = 0
        set packageName = ""
    }
    quit packageName
}

/// Returns the namespace <var>internalName</var> is mapped in from, or "" if it lives in the current
/// namespace or in a database - IRISLIB, ENSLIB - that is no namespace's own. <var>resolved</var> is
/// false if the item is mapped in from somewhere but where could not be established.
ClassMethod SourceNamespace(internalName As %String, Output resolved As %Boolean) As %String [ Internal ]
{
    set resolved = 1
    if '##class(%Library.RoutineMgr).IsMapped(internalName, .sourceDB) {
        quit ""
    }
    set sourceNamespace = ..NamespaceForDatabase(sourceDB, .resolved)
    quit $select(sourceNamespace = $namespace:"", 1:sourceNamespace)
}

/// Returns the namespace whose default routine database is <var>database</var> - in the "^^/dir/" or
/// "^server^/dir/" form reported by <method>%Library.RoutineMgr.IsMapped</method> - or "" if no
/// namespace has it, as is the case for the library databases every namespace maps code in from.
/// <var>resolved</var> is false if the question could not be answered.
/// <p>%IPM.ExtensionBase.CompositeMethodOverrides:FindNamespaceForDatabase answers this by querying the
/// configuration in %SYS, which an ordinary developer has no privileges for; %SYS.Namespace answers it
/// from the namespace we are already in.</p>
ClassMethod NamespaceForDatabase(database As %String, Output resolved As %Boolean) As %String [ Internal ]
{
    set resolved = 1
    // The mapping is fixed for the life of the process, and bulk operations ask about the same
    // handful of databases once per item.
    set cache = $name(^||SourceControl.Git.PackageManagerContext("namespaceForDatabase", $namespace, database))
    if $data(@cache, namespace) {
        quit namespace
    }

    set namespace = ""
    try {
        set key = ..DatabaseKey(database)
        do ##class(%SYS.Namespace).ListAll(.namespaces)
        set candidate = ""
        for {
            set candidate = $order(namespaces(candidate))
            quit:candidate=""
            // implied namespaces are database directories rather than namespaces to look for packages in
            continue:$extract(candidate)="^"
            // one unusable namespace - dismounted, misconfigured - must not stop the search
            try {
                set destination = ##class(%SYS.Namespace).GetRoutineDest(candidate)
            } catch e {
                set destination = ""
            }
            continue:destination=""
            continue:..DatabaseKey(destination)'=key
            // More than one namespace can have the same default routine database; any of them will
            // resolve the same set of packages, so take the first.
            set namespace = candidate
            quit
        }
    } catch e {
        set resolved = 0
    }
    if 'resolved {
        quit ""
    }
    set @cache = namespace
    quit namespace
}

/// Returns a comparable form of a routine database reference, which is reported as "^^/dir/" by
/// <method>%Library.RoutineMgr.IsMapped</method> and as "^/dir/" by
/// <method>%SYS.Namespace.GetRoutineDest</method>, and carries the server name for a remote database
/// in either case.
ClassMethod DatabaseKey(database As %String) As %String [ Internal, Private ]
{
    // drop the leading caret, then the server name if there is one
    set reference = $extract(database, 2, *)
    set server = ""
    if (reference [ "^") {
        set server = $piece(reference, "^")
        set reference = $piece(reference, "^", 2, *)
    }
    quit $zconvert(server, "U")_"^"_$zconvert(##class(%Library.File).NormalizeDirectory(reference), "U")
}

Method Dump()
{
    write !,"Package manager context: "
    write !?4,"InternalName: ",..InternalName
    write !?4,"Package: ",$select($isobject(..Package):..Package.Name,1:"<none>")
    write !?4,"Resource: ",$select($isobject(..ResourceReference):..ResourceReference.Name,1:"<none>")
    write !?4,"Default? ",$select(..IsInDefaultPackage:"Yes",1:"No")
    write !?4,"Git-enabled? ",$select(..IsInGitEnabledPackage:"Yes",1:"No"),!
}

}
