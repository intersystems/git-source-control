Class %zpkg.isc.sc.git.Socket Extends %CSP.WebSocket
{

Parameter CSPURL = "/isc/studio/usertemplates/gitsourcecontrol/%zpkg.isc.sc.git.Socket.cls";

Property OriginallyRedirected;

Property OriginalMnemonic;

Property OriginalDevice;

ClassMethod Run()
{
     If %request.Get("method") = "preview" {
		set branchName = ##class(SourceControl.Git.Utils).GetCurrentBranch()
		do ##class(SourceControl.Git.Utils).RunGitWithArgs(.errStream, .outStream, "fetch")
		kill errStream, outStream
		do ##class(SourceControl.Git.Utils).RunGitWithArgs(.errStream, .outStream, "log", "HEAD..origin", "--name-status")
     } ElseIf %request.Get("method") = "pull" {
         Do ##class(SourceControl.Git.API).Pull()
     } ElseIf %request.Get("method") = "init" {
         Do ##class(SourceControl.Git.Utils).Init()
		Write !,"Done."
     } ElseIf %request.Get("method") = "clone" {
         Set remote = %request.Get("remote")
         Do ##class(SourceControl.Git.Utils).Clone(remote)
		Write !,"Done."
     } ElseIf %request.Get("method") = "sshkeygen" {
         Do ##class(SourceControl.Git.Utils).GenerateSSHKeyPair()
		Write !,"Done."
     } Else {
         Write !!,"Invalid method selected.",!!
     }
}

Method OnPreServer() As %Status
{
     If '$System.Security.Check("%Development","USE") {
         Quit $$$ERROR($$$AccessDenied)
     }
	If (%request.Get("$NAMESPACE") '= "") {
		Set $Namespace = %request.Get("$NAMESPACE")
	}
	Quit $$$OK
}

Method Server() As %Status
{
	New %server
	Set tSC = $$$OK
	Set tRedirected = 0
	Try {
		$$$ThrowOnError(..StartOutputCapture())
		Set tRedirected = 1
		
		// In subclasses: Do Something that produces output to the current device.
		// It will be sent back to the client, Base64-encoded, over the web socket connection.
         Do ..Run()
	} Catch e {
		Do e.Log()
		Set tSC = e.AsStatus()
	}
	
	// Cleanup
	If tRedirected {
		Do ..EndOutputCapture()
	}
	Do ..EndServer()
	Quit tSC
}

Method StartOutputCapture() [ ProcedureBlock = 0 ]
{
	New tSC, tRedirected
	#dim ex As %Exception.AbstractException
	#dim tSC As %Status = $$$OK
	#dim tRedirected As %Boolean = 0
	Try {
		Set %server = $this
		Set ..OriginallyRedirected = 0
		Set ..OriginalMnemonic = ""
		Set ..OriginalDevice = $IO
		
		Set ..OriginallyRedirected = ##class(%Library.Device).ReDirectIO()
		Set ..OriginalMnemonic = ##class(%Library.Device).GetMnemonicRoutine()
		Use ..OriginalDevice::("^"_$ZNAME)
		Set tRedirected = 1
		Do ##class(%Library.Device).ReDirectIO(1)
	} Catch ex {
		Set tSC = ex.AsStatus()
		
		// In case of exception, clean up.
		If tRedirected && ##class(%Library.Device).ReDirectIO(0) {
			Use ..OriginalDevice
		}
		If (..OriginalMnemonic '= "") {
			Use ..OriginalDevice::("^"_..OriginalMnemonic)
		}
		If ..OriginallyRedirected {
			Do ##class(%Library.Device).ReDirectIO(1)
		}
	}
	
	Quit tSC
 
 #; Public entry points for I/O redirection
wstr(s)	Do write(s)
		Quit
wchr(a) Do write($char(a))
		Quit
wnl	Do write($$$EOL)
		Set $X = 0
		Quit
wff	Do wnl Quit
wtab(n) New tTab
		Set tTab = $J("",$S(n>$X:n-$X,1:0))
		Do write(tTab)
		Quit
write(str)
		// If there was an argumentless NEW, cache the output and leave it at that.
		// This will be output next time there's a write with %server in scope.
		If '$IsObject($Get(%server)) {
			Set ^||OutputCapture.Cache($i(^||OutputCapture.Cache)) = str
			Quit
		}
		
		// Restore previous I/O redirection settings.
		New tOriginalDevice,i
		Set tOriginalDevice = $io
		If ##class(%Library.Device).ReDirectIO(0) {
			Use tOriginalDevice
		}
		If (%server.OriginalMnemonic '= "") {
			Use tOriginalDevice::("^"_%server.OriginalMnemonic)
		}
		If %server.OriginallyRedirected {
			Do ##class(%Library.Device).ReDirectIO(1)
		}
		
		If $Data(^||OutputCapture.Cache) {
			For i=1:1:$Get(^||OutputCapture.Cache) {
				Do reallywrite(^||OutputCapture.Cache(i))
			}
			Kill ^||OutputCapture.Cache
		}
		
		// Write out Base64-Encoded string
		Do reallywrite(str)
		
		// Turn I/O redirection back on.
		Do ##class(%Library.Device).ReDirectIO(1)
		Use tOriginalDevice::("^"_$ZNAME)
		Quit
reallywrite(pString)
		New tMsg
		Set tMsg = {"content":(pString)} // This is handy because it handles escaping of newlines, etc.
		Do %server.Write($System.Encryption.Base64Encode(tMsg.%ToJSON()))
		Quit
rstr(len, time) Quit ""
rchr(time) Quit ""
}

Method EndOutputCapture()
{
	Set tSC = $$$OK
	Try {
		If (..OriginalMnemonic '= "") {
			Use ..OriginalDevice::("^"_..OriginalMnemonic)
		}
		If ..OriginallyRedirected {
			Do ##class(%Library.Device).ReDirectIO(1)
		}
	} Catch e {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

Method SendJSON(pObject As %DynamicAbstractObject)
{
	Set tOriginalDevice = $io
	If ##class(%Library.Device).ReDirectIO(0) {
		Use tOriginalDevice
	}
	If (..OriginalMnemonic '= "") {
		Use tOriginalDevice::("^"_..OriginalMnemonic)
	}
	If ..OriginallyRedirected {
		Do ##class(%Library.Device).ReDirectIO(1)
	}
	Do ..Write($System.Encryption.Base64Encode(pObject.%ToJSON()))
	Do ##class(%Library.Device).ReDirectIO(1)
	Use tOriginalDevice::("^"_$ZNAME)
}

}

