' VirtualBox lab VBscript for BSD Router Project
'
' Copyright (c) 2010, The BSDRP Development Team
' All rights reserved.
'
' Redistribution and use in source and binary forms, with or without
' modification, are permitted provided that the following conditions
' are met:
' 1. Redistributions of source code must retain the above copyright
'    notice, this list of conditions and the following disclaimer.
' 2. Redistributions in binary form must reproduce the above copyright
'    notice, this list of conditions and the following disclaimer in the
'    documentation and/or other materials provided with the distribution.
'
' THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS:::: AND
' ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
' IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
' ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
' FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
' DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
' OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
' HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
' LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
' OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
' SUCH DAMAGE.
'

'�Force declaration of variables before use
Option Explicit

Main()

Public VB_EXE, VB_HEADLESS, WORKING_DIR, BSDRP_VDI, TEXT, RELEASE, VM_ARCH, VM_CONSOLE, BSDRP_FILENAME, RETURN_CODE, NUMBER_VM, NUMBER_LAN

Sub Main()
	' Variables used
	Dim WshShell, WshProcessEnv
	
    ' Get environmeent Variables
	Set WshShell = WScript.CreateObject("WScript.Shell")
	Set WshProcessEnv = WshShell.Environment("Process")
	'WScript.Echo "ProgramFiles = " & WshProcessEnv("ProgramFiles")
	
	' Define variables
    VB_EXE = WshProcessEnv("VBOX_INSTALL_PATH") & "VBoxManage.exe"
	VB_HEADLESS = Chr(34) & WshProcessEnv("VBOX_INSTALL_PATH") & "VBoxHeadless.exe" & Chr(34)
	WORKING_DIR = WshProcessEnv("USERPROFILE") & "\.VirtualBox"
	
	Set WshShell = Nothing
	
    RELEASE = "BSD Router Project: VirtualBox lab VBscript"

    VB_EXE=check_VB(VB_EXE)
    
    'Wscript.Echo "DEBUG, You are using the VB in : " & VB_EXE
	
	BSDRP_VDI=check_existing_VDI()
	
	'Wscript.Echo "DEBUG: ARCH is " & VM_ARCH & " CONSOLE is " & VM_CONSOLE
	
	Do
		NUMBER_VM = InputBox( "How many routers do you want to use ? (between 2 and 9)" )

		'if NUMBER_VM < 2 then
		'	Wscript.Echo "Warning, incorrect user input: Will use 2 routers"
		'end if
	
		'if NUMBER_VM > 9 then
		'	Wscript.Echo "Warning, incorrect user input: Will use 9 routers"
		'end if
	
	Loop While ((NUMBER_VM < 2) OR (NUMBER_VM > 9))
	
	Do
		NUMBER_LAN = InputBox( "How many shared LAN between your routers do you want to have ? (between 0 and 4)" )
	
		'if NUMBER_LAN < 0 then
		'	Wscript.Echo "Warning, incorrect user input: Will use 0 shared LAN"
		'end if
		
		'if NUMBER_LAN > 9 then
		'	Wscript.Echo "Warning, incorrect user input: Will use 9 shared LAN"
		'end if
	
	Loop While ((NUMBER_LAN < 0) OR (NUMBER_LAN > 4))
	
	Wscript.Quit
	
    clone_vm()
	
	call MsgBox (TEXT,vbOk,RELEASE)
	
    start_vm()
   
End Sub

Function check_existing_VDI()
	
	dim fso, InitFSO, FILENAME
	
	Set fso = CreateObject("Scripting.FileSystemObject") 
	
	FILENAME= WORKING_DIR & "\BSDRP_FreeBSD_64_vga.vdi" 
	
    If (fso.FileExists(FILENAME)) Then
		VM_ARCH="FreeBSD_64"
		VM_CONSOLE="vga"
		check_existing_VDI=Chr(34) & FILENAME & Chr(34)
		Exit Function
	End if 
	
	FILENAME=WORKING_DIR & "\BSDRP_FreeBSD_vga.vdi"
	
    If (fso.FileExists(FILENAME)) Then
		VM_ARCH="FreeBSD"
		VM_CONSOLE="vga"
		check_existing_VDI=Chr(34) & FILENAME & Chr(34)
		Exit Function
	End if 
    
    FILENAME=WORKING_DIR & "\BSDRP_FreeBSD_64_serial.vdi"
	
    If (fso.FileExists(FILENAME)) Then
		VM_ARCH="FreeBSD_64"
		VM_CONSOLE="serial"
		check_existing_VDI=Chr(34) & FILENAME & Chr(34)
		Exit Function
	End if
	
	FILENAME=WORKING_DIR & "\BSDRP_FreeBSD_serial.vdi"
	
    If (fso.FileExists(FILENAME)) Then
		VM_ARCH="FreeBSD"
		VM_CONSOLE="serial"
		check_existing_VDI=Chr(34) & FILENAME & Chr(34)
		Exit Function
	End if 
    
    TEXT = "Please select a unzipped and unrenamed BSDRP image file" & vbCrLf & vbCrLf
    RETURN_CODE = MsgBox (TEXT,vbOkCancel,RELEASE)
    If RETURN_CODE = 2 Then
        wscript.quit
    End If

	set fso = Nothing
	
    ' Ask user for the BSDRP image file
   
	Set fso = CreateObject("UserAccounts.CommonDialog") 
	fso.Filter = "All BSDRP images file (*.img)|*.img|"
	InitFSO = fso.ShowOpen

	If InitFSO = False Then
		Wscript.Echo "Script Error: Please select a file!"
        Wscript.Quit
    End If
    
	FILENAME=fso.FileName
	
	set fso = Nothing
	
	' Getting ARCH and Console type for
	
	VM_ARCH=image_arch_detect(FILENAME)
	VM_CONSOLE=image_console_detect(FILENAME)
	
	convert_image_to_vdi(FILENAME)
	
	check_existing_VDI= Chr(34) & WORKING_DIR & "\BSDRP_" & VM_ARCH & "_" & VM_CONSOLE & ".vdi" & Chr(34)
	
End Function

Function check_VB(ByVal VB_EXE)
	dim fso, ObjFSO, InitFSO
	
    Set fso = CreateObject("Scripting.FileSystemObject")
   
    If Not (fso.FileExists(VB_EXE)) Then
        TEXT = "Can't found VirtualBox in " & vbCrLf & VB_EXE & vbCrLf
        TEXT = TEXT & "Please, select the VBmanager.exe location" & vbCrLf
        MsgBox  TEXT,vbCritical,"Error"
        
        Set ObjFSO = CreateObject("UserAccounts.CommonDialog") 
        InitFSO = ObjFSO.ShowOpen

       If InitFSO = False Then
            Wscript.Echo "Script Error: Please select a file!"
            Wscript.Quit
        Else
            check_VB=Chr(34) & ObjFSO.FileName & Chr(34)
        End If
    else
        check_VB=Chr(34) & VB_EXE & Chr(34)
    end if
	
	set fso = Nothing
   
End Function

Function image_arch_detect(ByVal BSDRP_FileName)
	if InStr(BSDRP_FileName, "amd64") then
		image_arch_detect="FreeBSD_64"
		Exit Function
	end if
	
	if InStr(BSDRP_FileName, "i386") then
		image_arch_detect="FreeBSD"
		Exit Function
	end if
	
	MsgBox  "Can't guests arch of this image: BSDRP file renamed ?",vbCritical,"Error"
	Wscript.Quit
   
End Function

Function image_console_detect(ByVal BSDRP_FileName)
	if InStr(BSDRP_FileName, "serial") then
		image_console_detect="serial"
		Exit Function
	end if
	
	if InStr(BSDRP_FileName, "vga") then
		image_console_detect="vga"
		Exit Function
	end if
	
	MsgBox  "Can't guests console of this image: BSDRP file renamed ?",vbCritical,"Error"
	Wscript.Quit
   
End Function

Function convert_image_to_vdi (ByVal BSDRP_FileName)
	dim fso, CMD, FILE
	Set fso = CreateObject("Scripting.FileSystemObject")
	FILE=WORKING_DIR & "\BSDRP_lab.vdi"
	'If (fso.FileExists(FILE)) Then
	'		CMD=VB_EXE & " closemedium disk " & Chr(34) & WORKING_DIR & "\BSDRP_lab.vdi" & Chr(34) & " --delete"
	'		call run (CMD,true)
	'		' fso.DeleteFile(FILE)
    'end if
	
	set fso = Nothing 
	
	' Convert the IMG file into a VDI file
	
	CMD=VB_EXE & " convertfromraw " & Chr(34) & BSDRP_FileName & Chr(34) & " " & Chr(34) & WORKING_DIR & "\BSDRP_" & VM_ARCH & "_" & VM_CONSOLE & ".vdi" & Chr(34)
	
	call run (CMD,true)
	
	' Now, we need to compress this file, but for this action, this file must be a member of an existing VM
	' *********** IS THE COMPRESSION VERY�USEFULL ??? *************************
	
	' Check existing BSDRP_lap_tempo vm before to register it!
	
	'if check_vm("BSDRP_Lab_Template") = 0 then
	'	if delete_vm("BSDRP_Lab_Template") > 0 then
	'		TEXT = "Can't delete the existing BSDRP_Lab_Template VM !"
	'		MsgBox  TEXT,vbCritical,"Error"
	'		wscript.quit
	'	end if
	'end if
	
	' Create the VM
	'CMD=VB_EXE & " createvm --name BSDRP_Lab_Template --ostype " & VM_ARCH & " --register"
	
	'call run(CMD,true)
	
	' Add a storage controller
	
	'CMD=VB_EXE & " storagectl BSDRP_Lab_Template --name " & Chr(34) & "SATA Controller" & Chr(34) & " --add sata --controller IntelAhci"
	
	'call run(CMD,true)
	
	' Add the VDI image disk
	
	'CMD=VB_EXE & " storageattach BSDRP_Lab_Template --storagectl " & Chr(34) & "SATA Controller" & Chr(34) & " --port 0 --device 0 --type hdd --medium " & Chr(34) & WORKING_DIR & "\BSDRP_lab.vdi" & Chr(34)
	
	'call run(CMD,true)
	
	' Reduce the VM Requirement
	
	'CMD=VB_EXE & " modifyvm BSDRP_Lab_Template --memory 16 --vram 1 "
	
	'call run(CMD,true)
	
	' Compress the VDI�
	
	'CMD=VB_EXE & " modifyvdi " & Chr(34) & WORKING_DIR & "\BSDRP_lab.vdi" & Chr(34) & " --compact"
	
	'call run(CMD,true)
	
	' Delete the VM
	
	'if delete_vm ("BSDRP_Lab_Template") > 0 then
	'	TEXT = "Error trying to delet the BSDRP_Lab_Template after image compression" & vbCrLf & vbCrLf
	'	MsgBox  TEXT,vbCritical,"Error"
	'	wscript.quit
	'end if
	

End Function

Function Run(ByVal CMD, ByVal MANAGE_ERROR)
' This function run the command CMD
' if MANAGE_ERROR is true, then this command manage error (display error and exit)
' if RETURNVAL is false, then this command silenty return RETURN_CODE

	Dim shell, ERRTEXT

    Set shell = CreateObject("WScript.Shell")
	'Wscript.Echo "DEBUG:" &  CMD
	Run = Shell.Run(CMD,1,True)
	if MANAGE_ERROR then
		if Run > 0 then
			ERRTEXT = "Error with this command" & vbCrLf & CMD & vbCrLf
			MsgBox  ERRTEXT,vbCritical,"Error"
			wscript.quit
		end If
	else
		Set shell = Nothing
	End if
	
End Function

Function check_vm(ByVal VM_NAME)
	Dim CMD
	
	CMD=VB_EXE & " showvminfo " & VM_NAME
		
	check_vm=run(CMD,false)

End Function

Function delete_vm(ByVal VM_NAME)
	Dim CMD
	
	CMD=VB_EXE & " storagectl " & VM_NAME & " --name " & Chr(34) & "SATA Controller" & Chr(34) & " --remove"
	
	delete_vm=run(CMD,false)
	
	CMD=VB_EXE & " unregistervm " & VM_NAME & " --delete"

	delete_vm=delete_vm + run(CMD,false)
	
	'CMD=VB_EXE & " closemedium disk " & Chr(34) & WORKING_DIR & "\" & VM_NAME & ".vdi" & Chr(34) " --delete
	
	'delete_vm=delete_vm + run(CMD,false)
	

	
End Function

' This function generate the clones
Function clone_vm ()
	Dim i,j,NIC_NUMBER,ERRTEXT,CMD
    TEXT = "Creating lab with " & NUMBER_VM & " routers:" & vbCrLf
    TEXT = TEXT & "- " & NUMBER_LAN & " LAN between all routers" & vbCrLf
    TEXT = TEXT &  "- Full mesh ethernet point-to-point link between each routers" & vbCrLf & vbCrLf
    i=1
    'Enter the main loop for each VM
    Do while i <= NUMBER_VM
        create_vm ("BSDRP_lab_R" & i)
        NIC_NUMBER=0
        TEXT = TEXT & "Router" & i & " have the folllowing NIC:" & vbCrLf
        'Enter in the Cross-over (Point-to-Point) NIC loop
        'Now generate X x (X-1)/2 full meshed link
        j=1
        Do while j <= NUMBER_VM
            if i <> j then
                TEXT = TEXT & "em" & NIC_NUMBER & " connected to Router" & j & vbCrLf
                NIC_NUMBER=NIC_NUMBER + 1
				if i <= j then
					CMD=VB_EXE & " modifyvm BSDRP_lab_R" & i & " --nic" & NIC_NUMBER & " intnet --nictype" & NIC_NUMBER & " 82540EM --intnet" & NIC_NUMBER & "  LAN" & i & j & " --macaddress" & NIC_NUMBER & " AAAA00000" & i & i & j
					call run(CMD,true)
                else
					CMD=VB_EXE & " modifyvm BSDRP_lab_R" & i & " --nic" & NIC_NUMBER & " intnet --nictype" & NIC_NUMBER & " 82540EM --intnet" & NIC_NUMBER & "  LAN" & j & i & " --macaddress" & NIC_NUMBER & " AAAA00000" & i & j & i
					call run(CMD,true)
                End if
            End if
			j = j + 1
        Loop
        'Enter in the LAN NIC loop
        j=1
        Do while j <= NUMBER_LAN
            TEXT = TEXT & "em" & NIC_NUMBER & " connected to LAN number " & j & vbCrLf
            NIC_NUMBER=NIC_NUMBER + 1
			CMD=VB_EXE & " modifyvm BSDRP_lab_R" & i & " --nic" & NIC_NUMBER & " intnet --nictype" & NIC_NUMBER & " 82540EM --intnet" & NIC_NUMBER & "  LAN10" & j & " --macaddress" & NIC_NUMBER & " CCCC00000" & j & "0" & i
			call run(CMD,true)			
            j = j + 1
        Loop
		i = i + 1
    Loop
End Function

Function create_vm (ByVal VM_NAME)
	dim ERRTEXT, fso, WshShell,CMD
    ' Check if the vm allready exist
    if check_vm (VM_NAME) > 0 then		
		
		' Create the VM (HOW VM_ARCH is define if re-using existing lab ??)
		CMD=VB_EXE & " createvm --name " & VM_NAME & " --ostype " & VM_ARCH & " --register"
		call run(CMD,true)
		
		' Clone the Template vdi
		CMD=VB_EXE & " clonehd " & Chr(34) & WORKING_DIR & "\BSDRP_lab.vdi" & Chr(34) & " " & VM_NAME & ".vdi"
		call run(CMD,true)
		
		' Add SATA controller to the VM
		CMD=VB_EXE & " storagectl " & VM_NAME & " --name " & Chr(34) & "SATA Controller" & Chr(34) & " --add sata --controller IntelAhci"
		call run(CMD,true)
		
    	' Add the controller and disk to the VM...
		CMD=VB_EXE & " storageattach " & VM_NAME & " --storagectl " & Chr(34) & "SATA Controller" & Chr(34) & " --port 0 --device 0 --type hdd --medium " & VM_NAME & ".vdi" 
		call run(CMD,true)
		
    	'echo "Set the UUID of this disk..." >> ${LOG_FILE}
    	'VBoxManage internalcommands sethduuid $1.vdi >> ${LOG_FILE} 2>&1
    else
        ' if existing: Is running ?
		
		CMD=VB_EXE & " controlvm " & VM_NAME & " poweroff" 
		call run(CMD,false)
		
		' Sleep is not simple in VBS :-)
		set fso = CreateObject("Scripting.FileSystemObject")
		Set WshShell = WScript.CreateObject("WScript.Shell")
        WScript.Sleep 5
		
    End if
	
	CMD=VB_EXE & " modifyvm " & VM_NAME & " --audio none --memory 92 --vram 1 --boot1 disk --floppy disabled --biosbootmenu disabled"
	call run(CMD,true)

    if VM_CONSOLE="serial" then
		CMD=VB_EXE & " modifyvm " & VM_NAME & " --uart1 0x3F8 4 --uartmode1 server " & Chr(34) & WORKING_DIR & "\" & VM_NAME & ".serial" & Chr(34)
		call run(CMD,true)
    End if

End Function