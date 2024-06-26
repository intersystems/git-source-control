Include %callout

/// Encapsulates the XSLT String Buffer XDEV device. <br />
/// Note that only one <class>SourceControl.Git.Util.Buffer</class> instance may be used at a time per job.
Class SourceControl.Git.Util.Buffer Extends %RegisteredObject
{

/// Size of the XSLT string buffer, in MB. <br />
/// Changes will only take effect the next time <method>BeginCaptureOutput</method>() is called. <br />
Property StringBufferSize As %Integer [ InitialExpression = 25 ];

/// Corresponds to "C" mode flag in device open. <br />
/// May be changed after <method>BeginCaptureOutput</method>() is called and the XDEV device is open. <br />
Property CarriageReturnMode As %Boolean [ InitialExpression = 1 ];

Method CarriageReturnModeSet(value As %Boolean) As %Status
{
	Set tSC = $$$OK
	Set tIO = $io
	Try {
		Set tValue = ''value
		If ..DeviceOpen {
			Set tModeChange = $Select(tValue: "+", 1: "-")_"C"
			Use ..Device:(::tModeChange)
		}
	} Catch e {
		Set tSC = e.AsStatus()
	}
	Use tIO
	If $$$ISOK(tSC) {
		Set i%CarriageReturnMode = tValue
	}
	Quit tSC
}

/// Translate Table to use - by default, UTF8 for unicode instances, RAW otherwise. <br />
/// May be changed after <method>BeginCaptureOutput</method>() is called and the XDEV device is open. <br />
Property TranslateTable As %String [ InitialExpression = {$select($$$IsUnicode:"UTF8",1:"RAW")} ];

Method TranslateTableSet(value As %String) As %Status
{
	Set tSC = $$$OK
	Set tIO = $io
	Try {
		// TODO: validate that value is a valid TranslateTable, especially when ..DeviceOpen = 0
		If ..DeviceOpen {
			Use ..Device:(/IOT=value)
		}
	} Catch e {
		Set tSC = e.AsStatus()
	}
	Use tIO
	If $$$ISOK(tSC) {
		Set i%TranslateTable = value
	}
	Quit tSC
}

/// Input buffer size, in bytes. <br />
/// Changes will only take effect the next time <method>BeginCaptureOutput</method>() is called. <br />
Property InputBufferSize As %Integer(MAXVAL = 1048576, MINVAL = 1024) [ InitialExpression = 16384 ];

/// Output buffer size, in bytes. <br />
/// Changes will only take effect the next time <method>BeginCaptureOutput</method>() is called. <br />
Property OutputBufferSize As %Integer(MAXVAL = 1048576, MINVAL = 1024) [ InitialExpression = 16384 ];

/// Name of XDEV device.
Property Device As %String [ Internal, Private ];

/// Tracks whether <property>Device</property> is currently open.
Property DeviceOpen As %Boolean [ InitialExpression = 0, Internal, Private ];

/// Keeps track of the previously opened device.
Property PreviousDevice As %String [ Internal, Private ];

/// Keeps track of the previous state of the I/O redirection flag
Property PreviousIORedirectFlag As %Boolean [ Internal, Private ];

/// Keeps track of the previous mnemonic routine
Property PreviousMnemonicRoutine As %String [ Internal, Private ];

/// Initializes the device name for this object.
Method %OnNew() As %Status [ Private, ServerOnly = 1 ]
{
	// Multiple processes can use the same XDEV device name without conflict, so we can use the object reference to identify the device.
	Set ..Device = "|XDEV|"_(+$This)
	Quit $$$OK
}

/// Begins capturing output. <br />
Method BeginCaptureOutput() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tModeParams = $Select(..CarriageReturnMode: "C", 1: "")_"S"
		Close ..Device
		Open ..Device:($ZF(-6,$$$XSLTLibrary,12):..StringBufferSize:tModeParams:/HOSTNAME="XSLT":/IOT=..TranslateTable:/IBU=..InputBufferSize:/OBU=..OutputBufferSize)
    	Set ..DeviceOpen = 1
    	Set ..PreviousDevice = $io
    	Set ..PreviousIORedirectFlag = ##class(%Library.Device).ReDirectIO()
    	Set ..PreviousMnemonicRoutine = ##class(%Library.Device).GetMnemonicRoutine()
    	Use ..Device
    	If ..PreviousIORedirectFlag {
    		Do ##class(%Library.Device).ReDirectIO(0)
    	}
	} Catch e {
		Set tSC = e.AsStatus()
		Close ..Device
		Set ..DeviceOpen = 0
	}
	Quit tSC
}

/// Reads all output from the buffer to stream <var>pStream</var>,
/// which will be initialized as a <class>%Stream.TmpBinary</class> object if not provided.
Method ReadToStream(ByRef pStream As %Stream.Object) As %Status
{
	Set tSC = $$$OK
	Set tOldIO = $io
	Try {
		If '$IsObject($Get(pStream)) {
			Set pStream = ##class(%Stream.TmpBinary).%New()
		}
		
		If '..DeviceOpen {
			// No-op
			Quit
		}
		
		Use ..Device
		
		// Flush any remaining output
		Write *-3
		
		// Stream
		If pStream.%IsA("%Stream.FileCharacter") {
			// Force stream's file to open
			Set tSC = pStream.Write("")
			If $$$ISERR(tSC) {
				Quit
			}
			
			Set tFile = pStream.Filename
		    For {
				Use ..Device
				Set tChunk = ""
				Try {
					Read tChunk:0
				} Catch {}
				If '$Length(tChunk) {
					Quit
				}
				Use tFile
				Write tChunk
		    }
		}
	    Else {
		    For {
				Use ..Device
				Set tChunk = ""
				Try {
					Read tChunk:0
				} Catch {}
				If '$Length(tChunk) {
					Quit
				}
				Do pStream.Write(tChunk)
		    }
	    }
	} Catch e {
		If e.Name="<ENDOFFILE>" {
			Set tSC = $$$OK
		} Else {
			Set tSC = e.AsStatus()
		}
	}
	Use tOldIO
	Quit tSC
}

/// Reads all output from the buffer to <var>pString</var>.
Method ReadToString(Output pString As %String) As %Status
{
	Set tSC = $$$OK
	Set tOldIO = $io
	Set pString = $Get(pString)
	Try {
		If '..DeviceOpen {
			// No-op
			Quit
		}
		
		Use ..Device
		
		// Flush any remaining output
		Write *-3
		
		// String
		For {
			Use ..Device
			Set tChunk = ""
			Try {
				Read tChunk:0
			} Catch {}
			If '$Length(tChunk) {
				Quit
			}
			Set pString = pString _ tChunk
		}
	} Catch e {
		If e.Name="<ENDOFFILE>" {
			Set tSC = $$$OK
		} Else {
			Set tSC = e.AsStatus()
		}
	}
	Use tOldIO
	Quit tSC
}

/// Ends capturing output <br />
/// If <var>pOutput</var> is any sort of stream, output will be written to it. <br />
/// Otherwise, it will be returned as a string (initialized to "" before retrieving output from the buffer). <br />
Method EndCaptureOutput(ByRef pOutput) As %Status
{
	Set tSC = $$$OK
	Set tOldIO = $io
	Try {
		Set pOutput = $Get(pOutput)
		
		If $IsObject(pOutput) && pOutput.%IsA("%Stream.Object") {
			Set tSC = ..ReadToStream(.pOutput)
		} Else {
			Set tSC = ..ReadToString(.pOutput)
		}
	} Catch e {
		Set tSC = e.AsStatus()
	}
	
	// Close the XDEV device, and switch back to the original device
	Try {
		If (tOldIO = ..Device) {
			Do ..UsePreviousDeviceAndSettings()
		} Else {
			Use tOldIO
		}
		Close ..Device
	} Catch e {
		Set tSC = $$$ADDSC(tSC,e.AsStatus())
	}
	Quit tSC
}

Method %OnClose() As %Status [ Private, ServerOnly = 1 ]
{
	If (..Device '= "") {
		If ($io = ..Device) {
			// Switch back to the previous device if possible; if this fails, the subsequent
			// close of ..Device will switch back to the principal device.
			Try {
				Do ..UsePreviousDeviceAndSettings()
			} Catch e {}
		}
		Close ..Device
	}
    Set ..DeviceOpen = 0
	
	Quit $$$OK
}

Method UsePreviousDeviceAndSettings() [ Internal, Private ]
{
	Use ..PreviousDevice
	If (..PreviousMnemonicRoutine '= "") {
		Set tOldMnemonic = "^"_..PreviousMnemonicRoutine
		Use ..PreviousDevice::(tOldMnemonic)
	}
	If ..PreviousIORedirectFlag {
		Do ##class(%Library.Device).ReDirectIO(1)
	}
}

}

