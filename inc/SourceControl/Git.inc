ROUTINE SourceControl.Git [Type=INC]
#define SourceRoot $get(^SYS("SourceControl","Git","settings","namespaceTemp"))
#def1arg SourceMapping(%arg) ^SYS("SourceControl","Git","settings","mappings",%arg)
#def1arg GetSourceMapping(%arg) $Get($$$SourceMapping(%arg))
#def1arg NewLineIfNonEmptyStream(%arg) if %arg.Size > 0 write !
#def1arg TrackedItems(%arg) ^SYS("SourceControl","Git","items", %arg)
