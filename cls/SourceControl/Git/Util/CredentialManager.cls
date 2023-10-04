Class SourceControl.Git.Util.CredentialManager Extends %RegisteredObject
{

/// Description
Property pvtStore [ Internal, Private ];

ClassMethod Test()
{
	Do ##class(SourceControl.Git.Util.CredentialManager).Stop()

	set username = "testUser"
	w "Getting token for user """_username_""", expect error", !
	set token = ..GetToken(username, .err, .code)
	zw token, err, code

	set token = "testToken"
	w !, "Setting token """_token_""" for user """_username_"""", !
	do ..SetToken(username, token, .err, .code)
	zw err, code

	w !, "Getting token for user "_username_", expect to get token """_token_"""", !
	set token = ..GetToken(username, .err, .code)
	zw token, err, code
}

ClassMethod Test2()
{
	set username = "testUser"
	set token = ..GetToken(username, .err, .code)
	zw token, err, code
}

Method Run()
{
	do ##class(%SYSTEM.Event).Create(..GetEventName())

	set i%pvtStore = ##class(PrivateMemoryStore).%New()
	set code = 0
	while (code '= -1) {
		try {
			set code = ..Wait(.msgType, .msgContent)
			if (code = 1) {
				do ..LogForDaemon("Code: "_code_" "_"Received "_msgType_" && "_ " "_msgContent)
				do ..HandleMessage(msgType, msgContent)
			}
		} catch err {
			do err.Log()
		}
	}
}

ClassMethod GetToken(gitUsername As %String, Output error As %String, Output code As %String) As %String
{
	set $lb(token, error) = ..Signal("GET", $lb($JOB, gitUsername), .code)
	return token
}

ClassMethod SetToken(gitUsername As %String, gitToken As %String, Output error As %String, Output code)
{
	set $lb(, error) = ..Signal("SET", $lb($JOB, gitUsername, gitToken), .code)
}

ClassMethod SendResponse(toPID As %Integer, message As %String, error As %String)
{
	if $System.Event.Signal(toPID, $lb(message, error)) '= 1 {
		do ..LogForDaemon("Unable to send message: """_message_""" to: "_toPID)
	}
}

Method HandleMessage(msgType As %String, msgContent)
{
	try {
		// make sure the message is appropriately formatted
		set $lb(senderPID, gitUsername, gitToken) = msgContent
	} catch err {
		do err.Log()
		quit
	}
		
	if '$data(senderPID) {
		do ..LogForDaemon("No source PID provided")
		quit
	}

	if '$data(gitUsername) {
		do ..SendResponse(senderPID, "", "provide username")
		quit
	}
	


	set irisUsername = ##class(%SYS.ProcessQuery).%OpenId(senderPID).UserName
	// key that the token would be mapped from 
	set key = $lb(irisUsername, gitUsername)
	if msgType = "GET" {
		if i%pvtStore.KeyExists(key) {
			do ..SendResponse(senderPID, i%pvtStore.Retrieve(key), "")
		} else {
			do ..SendResponse(senderPID, "", "key does not exist")
		}
	} elseif msgType = "SET"  {
		if '$data(gitToken) {
			do ..SendResponse(senderPID, "", "provide git token")
			quit
		}
		do i%pvtStore.Store(key, gitToken)
		do ..SendResponse(senderPID, gitToken, "")
	}
}

ClassMethod Signal(msgType As %String, msgContent As %String, Output responseCode) As %String
{
	// Make sure the daemon is running
	do ..Start()

	// Clear any pending messages for this process' resource
	do $System.Event.Clear($Job)

	// Signal the daemon
	do ##class(%SYSTEM.Event).Signal(..GetEventName(),$ListBuild(msgType,msgContent))
	set $listbuild(responseCode,msg) = $System.Event.WaitMsg("",5)
	return msg
}

Method Wait(Output msgType As %String, Output msgContent As %String) As %Integer
{
	set (msg,msgType,msgContent) = ""
	set $listbuild(code,msg) = ##class(%SYSTEM.Event).WaitMsg(..GetEventName(),1)
	if $listvalid(msg) {
		set $listbuild(msgType,msgContent) = msg
	}
	return code
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
		do LogForDaemon(err.DisplayString())
	}
}

ClassMethod Stop()
{
	do ##class(%SYSTEM.Event).Delete(..GetEventName())
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
	return $$$OK
}

ClassMethod LogForDaemon(msg) As %Status
{
	do ..LogToApplicationErrors("!!!Credential Manager Deamon!!!"_$c(13,10)_msg)
}

ClassMethod LogToApplicationErrors(msg) As %Status
{
	try {
		do LOG^%ETN(msg)
		set sc=$$$OK
	} catch err {
		set sc=err.AsStatus()
	}
	return sc
}

}
