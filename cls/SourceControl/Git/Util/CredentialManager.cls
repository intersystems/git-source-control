Class SourceControl.Git.Util.CredentialManager Extends %RegisteredObject
{

/// Description
Property pvtStore [ Internal, Private ];

ClassMethod Test()
{
	Do ##class(SourceControl.Git.Util.CredentialManager).Stop()
	Set response = ##class(SourceControl.Git.Util.CredentialManager).Signal("getUsername",$job,.code)
	Write ! zw response,code
	Set response = ##class(SourceControl.Git.Util.CredentialManager).Signal("fakeType",$job,.code)
	Write ! zw response,code
}

Method Run()
{
	do ##class(%SYSTEM.Event).Create(..GetEventName())

	set i%pvtStore = ##class(PrivateMemoryStore).%New()
	set code = 0
	while (code '= -1) {
		try {
			set code = ..Wait(.msgType, .senderPID)
			if (code = 1) {
				do ..DaemonLogger("Code: "_code_" "_"Received "_msgType_" && "_ " "_senderPID)
				do ..HandleMessage(msgType, senderPID)
			}
		} catch err {
			do err.Log()
		}
	}
}

ClassMethod HandleMessage(msgType, senderPID)
{
	set username = $System.Process.UserName(senderPID)
}

ClassMethod Signal(msgType As %String, msgContent As %String, Output responseCode) As %String
{
	// Make sure the daemon is running
	do ..Start()

	write "Event defined? ",$System.Event.Defined(..GetEventName()),!

	// Clear any pending messages for this process' resource
	do $System.Event.Clear($Job)

	// Signal the daemon
	do ##class(%SYSTEM.Event).Signal(..GetEventName(),$ListBuild(msgType,msgContent))
	set $listbuild(responseCode,msg) = $System.Event.WaitMsg("",5)
	quit msg
}

Method Wait(Output msgType As %String, Output senderPID As %String) As %Integer
{
	set (msg,msgType,senderPID) = ""
	set $listbuild(code,msg) = ##class(%SYSTEM.Event).WaitMsg(..GetEventName(),1)
	if $listvalid(msg) {
		set $listbuild(msgType,senderPID) = msg
	}
	quit code
}

ClassMethod GetEventName() As %String
{
	return $Name(^isc.git.sc("Daemon")) //^"_$classname()
}

ClassMethod Start()
{
	if ..CheckStatus() {
		quit
	}
	job ..StartInternal():(:::1):5
	if ('$test) {
		$$$ThrowStatus($$$ERROR($$$GeneralError,"Daemon process failed to start"))
	}
	while '$System.Event.Defined(..GetEventName()) {
		hang 1
		if $increment(wait) > 5 {
			// this is a no-no situation, right?
			// we would never want to return from Start without starting
			quit
		}
	}
}

ClassMethod StartInternal()
{
	try {
		set lock = $System.AutoLock.Lock(..GetEventName(), , 2)
		set daemon = ..%New()
		do daemon.Run()
	} catch err {
		do err.Log()
	}
}

ClassMethod Stop()
{
	set deleted = ##class(%SYSTEM.Event).Delete(..GetEventName())
	w "deleted the event? ", deleted, !
	set pid = ^$LOCK(..GetEventName(), "OWNER")
	if (pid > 0) {
		do $System.Process.Terminate(pid)
	}
}

ClassMethod Restart()
{
	do ..Stop()
	do ..Start()
}

ClassMethod CheckStatus() As %Boolean
{
	return ($data(^$LOCK(..GetEventName())) = 10)
}

/// This callback method is invoked by the <METHOD>%Close</METHOD> method to 
/// provide notification that the current object is being closed.
/// 
/// <P>The return value of this method is ignored.
Method %OnClose() As %Status [ Private, ServerOnly = 1 ]
{
	do ##class(%SYSTEM.Event).Delete(..GetEventName())
	quit $$$OK
}

Method DaemonLogger(msg) As %Status
{
	try {
		do LOG^%ETN("!!!Daemon Message!!!"_msg)
		set sc=$$$OK
	} catch err {
		set sc=err.AsStatus()
	}
	quit sc
}

}
