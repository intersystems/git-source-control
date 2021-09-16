ROUTINE SourceControl.Git [Type=INC]
#define SourceRoot $get(^SYS("SourceControl","Git","settings","namespaceTemp"))
#def1arg SourceMapping(%arg) ^SYS("SourceControl","Git","settings","mappings",%arg)
#def1arg GetSourceMapping(%arg) $Get($$$SourceMapping(%arg))


