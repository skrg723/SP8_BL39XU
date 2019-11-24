#pragma rtGlobals=3		// Use modern global access method and strict wave access.

 
/////26th, Oct. 2019: ver1.0		S.Sakuragi
/////使い方
/////コンパイルするとMacrosバーのところにデータ取り込みのメニューが出ます。
/////"MCD: load file"を選択すると、指定ファイル1つだけを取り込みます。
/////"MCD: load folder"を選択すると、指定フォルダ内の未取り込み".dat"ファイルを全て取り込みます。
/////
/////同じ名前(例えば"hogehogePtL2_8K_(測定番号00x, 磁場の正負(p or n)).dat")といったデータファイルなら、一括で積算が行えます。
/////データ取り込み後に、データブラウザでデータの保存フォルダを指定(よくわからなければ、cd MCD_loaderを実行してください)後、
/////下記コマンドを入力すると、積算が実行されます。
/////sekisan("XMCD_FePtMgO_PtL2_8K")
/////磁場が正のときと負のとき(データ末尾がpかnか)のデータを用いてバックグラウンド補正が行えます。
/////積算結果は"hogehoge_pxasM"や、"hogehoge_mcdM"といった感じで出力されます。
/////
/////雑に作ったマクロなので高速化とかしていませんし、グチャグチャにループや処理が入り乱れています。すみません。
/////あとは実験中に使いやすいように手直しして配布し直すかもしれません。
/////
/////
/////22th, Nov. 2019: ver1.1		S.Sakuragi
/////XMCDヒステリシス測定の読み込み・積算の機能追加
/////ESM_sekisan("hogehoge")
/////"ESM: load file"
/////
/////
/////24th, Nov. 2019: ver1.1.1		S.Sakuragi
/////ESMの軽微な修正
/////関数: ESM_sekisan("hogehoge")
/////Macroメニュー"ESM: load folder"
/////Macroメニュー"ESM: load file"
/////
/////


Menu "Macros"
	"MCD: load folder", load_folder()
	"MCD: load file", load_file()
	"ESM: load folder", load_ESM_folder()
	"ESM: load file", load_ESM_file()
//	"_LoadMCD", LoadMCD(path, fname, wnini)
//	"_LoadMCD_CT32_sum", LoadMCD_CT32_sum(path, fname, wnini, fluo_SCA, total_SCA, deadTime, SDD_ElementMask, ESM_flag)
End

Function load_file()
	String cdf=GetDataFolder(1)
	NewPath/O/Q/M="Select data folder" path
 	if (V_flag != 0) 
		return -1; 
 	endif
 	pathinfo path
 	String name; Variable i
 	Prompt name, "select file", popup, IndexedFile(path, -1, ".dat")
	print name
	DoPrompt "file loader", name
	If(V_flag)
		abort
	Endif
	string fileID
	NewDataFolder/O/S root:MCD_loader
	SetDatafolder root:MCD_loader
	String str=hoge(name, fileID, i); str=ReplaceString(";", str, "")
	name=ReplaceString(".dat", name, ""); name=ReplaceString("-", name, "")
	scale_and_note()

	variable a = 5.4297094		// Si lattice constant at LN2 temperature,  in Angstrom
	variable h = 1, k = 1, l = 1
	wave loadnum1, loadnum8
	loadnum8 =  theta_to_E(loadnum1, a, h, k, l)
	Rename loadnum0 $name + "_ene"
	Rename loadnum1 $name + "_theta"
	Rename loadnum6 $name + "_mcd"
	Rename loadnum7 $name + "_xas"
	Rename loadnum8 $name + "_eneMeas"
	KillDataFolder $str
	cd cdf
End

Function load_folder()
	String cdf=GetDataFolder(1)
	NewPath/O/Q/M="Select data folder" path
 	if (V_flag != 0) 
		return -1; // User cancelled. 
 	endif
 	pathinfo path
 	String list = IndexedFile(path, -1, ".dat"); list = SortList(list, ";", 16)
	Variable num=ItemsInList(list), i
	String fileID
	NewDataFolder/O/S root:MCD_loader
	SetDatafolder root:MCD_loader
	If(WaveExists($"file_name")==0)
		Make/O/T/N=(0) file_name; Wave/T wvname=file_name 
	Else
		Wave/T wvname=file_name 
	Endif
	killwaves file_name
	For(i=0; i<num; i+=1)
		String name=StringFromList(i, list); name=ReplaceString(".dat", name, ""); name=ReplaceString("-", name, "")
		Variable n=check_name(name, wvname)
		If(n!=0)
			String str=hoge(list, fileID, i); str=ReplaceString(";", str, "")
			name=ReplaceString(".dat", name, ""); name=ReplaceString("-", name, "")
			scale_and_note()
			variable a = 5.4297094		// Si lattice constant at LN2 temperature,  in Angstrom
			variable h = 1, k = 1, l = 1
			wave loadnum1, loadnum8
			loadnum8 =  theta_to_E(loadnum1, a, h, k, l)
			Rename loadnum0 $name + "_ene"
			Rename loadnum1 $name + "_theta"
			Rename loadnum6 $name + "_mcd"
			Rename loadnum7 $name + "_xas"
			Rename loadnum8 $name + "_eneMeas"
			KillDataFolder $str
		Endif
	Endfor
	cd cdf
End


Function/S hoge(list, fileID, i)
	string fileID 
	Variable i 
	string list
	wave loadnote, loadInfo, loadMat
	String name=StringFromList(i,list), indent
	Loadwave/j/q/F={1,99,-2}/k=2/n=loadnote /P=path name

	LoadWave/G/D/Q/N=loadnum /P=path name
End

Function scale_and_note()
	wave loadnum0,loadnum1,loadnum6,loadnum7, loadnum8
	wave/T loadnote0
	wave  loadnum2, loadnum3, loadnum4, loadnum5
	variable j 
	
	sort loadnum0,loadnum0,loadnum1,loadnum6,loadnum7
	loadnum0 = loadnum0 * 1000
	SetScale/I x loadnum0[0],loadnum0[numpnts(loadnum0)-1],"eV", loadnum0, loadnum6, loadnum7
	
	Redimension /N=3 loadnote0
	for(j=0; j<3; j+=1)
		Note loadnum0, loadnote0[j]
	endfor
	for(j=0; j<3; j+=1)
		Note loadnum1, loadnote0[j]
	endfor
	for(j=0; j<3; j+=1)
		Note loadnum6, loadnote0[j]
	endfor
	for(j=0; j<3; j+=1)
		Note loadnum7, loadnote0[j]
	endfor
	for(j=0; j<3; j+=1)
		Note loadnum8, loadnote0[j]
	endfor
	Killwaves loadnote0, loadnum2, loadnum3, loadnum4, loadnum5
End


Function/D check_name(name, wvname)
	String name; Wave/T wvname
	Variable num=DimSize(wvname, 0), i, c=1
	For(i=0; i<num; i+=1)
		String str=wvname[i]
		If(cmpstr(name, str)==0)
			c=0*c
		Endif
	Endfor
	return c
End


function sekisan(wv)
	string wv
	make/O dumm_pxas
	String wvname_pxas = wv +"*p_xas"
	String list = wavelist(wvname_pxas,";",""); list = SortList(list, ";", 16)
	Variable num=ItemsInList(list), i
	For(i=0; i<num; i+=1)
		String name_pxas=StringFromList(i, list)
		wave wave_pxas=$name_pxas
		variable size=dimsize(wave_pxas,0)
		redimension/N=(size) dumm_pxas
		dumm_pxas = dumm_pxas +wave_pxas
		copyscales wave_pxas, dumm_pxas
	Endfor
	dumm_pxas = dumm_pxas/num
	duplicate/O dumm_pxas $wv +"_pxasM"

	make/O dumm_pmcd
	String wvname_pmcd = wv +"*p_mcd"
	String list_pmcd = wavelist(wvname_pmcd,";",""); list_pmcd = SortList(list_pmcd, ";", 16)
	Variable num_pmcd=ItemsInList(list_pmcd), j
	For(j=0; j<num_pmcd; j+=1)
		String name_pmcd=StringFromList(j, list_pmcd)
		wave wave_pmcd=$name_pmcd
		variable size_pmcd=dimsize(wave_pmcd,0)
		redimension/N=(size_pmcd) dumm_pmcd
		dumm_pmcd = dumm_pmcd +wave_pmcd
		copyscales wave_pmcd, dumm_pmcd
	Endfor
	dumm_pmcd = dumm_pmcd /num_pmcd
	duplicate/O dumm_pmcd $wv +"_pmcdM"

	make/O dumm_nxas
	String wvname_nxas = wv +"*n_xas"
	String listn = wavelist(wvname_nxas,";",""); listn = SortList(listn, ";", 16)
	Variable numn=ItemsInList(listn), k
	For(k=0; k<numn; k+=1)
		String name_nxas=StringFromList(k, listn)
		wave wave_nxas=$name_nxas
		variable sizen=dimsize(wave_nxas,0)
		redimension/N=(sizen) dumm_nxas
		dumm_nxas = dumm_nxas+wave_nxas
		copyscales wave_nxas, dumm_nxas
	Endfor
	dumm_nxas = dumm_nxas/num
	duplicate/O dumm_nxas $wv +"_nxasM"

	make/O dumm_nmcd
	String wvname_mmcd = wv +"*n_mcd"
	String list_mmcd = wavelist(wvname_mmcd,";",""); list_mmcd = SortList(list_mmcd, ";", 16)
	print list_mmcd
	Variable num_mmcd=ItemsInList(list_mmcd), l
	For(l=0; l<num_mmcd; l+=1)
		String name_mmcd=StringFromList(l, list_mmcd)
		wave wave_mmcd=$name_mmcd
		variable size_mmcd=dimsize(wave_mmcd,0)
		redimension/N=(size_mmcd) dumm_nmcd
		dumm_nmcd = dumm_nmcd+wave_mmcd
		copyscales wave_mmcd, dumm_nmcd
	Endfor
	dumm_nmcd = dumm_nmcd/num_mmcd 
	duplicate/O dumm_nmcd $wv +"_nmcdM"

	duplicate /O dumm_pxas xasM
	duplicate /O dumm_pmcd mcdM
	xasM = (dumm_pxas + dumm_nxas)/2
	xasM=xasM/2
	mcdM= (dumm_pmcd - dumm_nmcd)/2
	duplicate/O xasM $wv +"_xasM"
	duplicate/O mcdM $wv +"_mcdM"	
	killwaves dumm_pxas, dumm_nxas,dumm_pmcd,dumm_nmcd, xasM,mcdM
	
end

/////////
/////2019.11.22	
/////////

Function load_ESM_file()
	String cdf=GetDataFolder(1)
	NewPath/O/Q/M="Select data folder" path
 	if (V_flag != 0) 
		return -1; 
 	endif
 	pathinfo path
 	String name; Variable i
 	Prompt name, "select file", popup, IndexedFile(path, -1, ".dat")
	print name
	DoPrompt "file loader", name
	If(V_flag)
		abort
	Endif
	string fileID
	NewDataFolder/O/S root:ESM_loader
	SetDatafolder root:ESM_loader
	String str=hoge(name, fileID, i); str=ReplaceString(";", str, "")
	name=ReplaceString(".dat", name, ""); name=ReplaceString("-", name, "")
	//scale_and_note()

//	variable a = 5.4297094		// Si lattice constant at LN2 temperature,  in Angstrom
//	variable h = 1, k = 1, l = 1
//	wave loadnum1, loadnum8
//	loadnum8 =  theta_to_E(loadnum1, a, h, k, l)
	Rename loadnum0 $name + "_ene"
	Rename loadnum2 $name + "_field"
	Rename loadnum6 $name + "_MCD"
	Rename loadnum7 $name + "_xas"
//	Rename loadnum8 $name + "_eneMeas"
	wave loadnum1,loadnum3,loadnum4,loadnum5, loadnum8
	wave/T loadnote0
	Killwaves loadnote0,loadnum1,loadnum3,loadnum4,loadnum5,loadnum8
	KillDataFolder $str
	cd cdf
End

Function load_ESM_folder()
	String cdf=GetDataFolder(1)
	NewPath/O/Q/M="Select data folder" path
 	if (V_flag != 0) 
		return -1; // User cancelled. 
 	endif
 	pathinfo path
 	String list = IndexedFile(path, -1, ".dat"); list = SortList(list, ";", 16)
	Variable num=ItemsInList(list), i
	String fileID
	NewDataFolder/O/S root:ESM_loader
	SetDatafolder root:ESM_loader
	If(WaveExists($"file_name")==0)
		Make/O/T/N=(0) file_name; Wave/T wvname=file_name 
	Else
		Wave/T wvname=file_name 
	Endif
	killwaves file_name
	For(i=0; i<num; i+=1)
		String name=StringFromList(i, list); name=ReplaceString(".dat", name, ""); name=ReplaceString("-", name, "")
		Variable n=check_name(name, wvname)
		If(n!=0)
			String str=hoge(list, fileID, i); str=ReplaceString(";", str, "")
			name=ReplaceString(".dat", name, ""); name=ReplaceString("-", name, "")
			//scale_and_note()
		
		//	variable a = 5.4297094		// Si lattice constant at LN2 temperature,  in Angstrom
		//	variable h = 1, k = 1, l = 1
		//	wave loadnum1, loadnum8
		//	loadnum8 =  theta_to_E(loadnum1, a, h, k, l)
			Rename loadnum0 $name + "_ene"
			Rename loadnum2 $name + "_field"
			Rename loadnum6 $name + "_MCD"
			Rename loadnum7 $name + "_xas"
		//	Rename loadnum8 $name + "_eneMeas"
			wave loadnum1,loadnum3,loadnum4,loadnum5, loadnum8
			wave/T loadnote0
			Killwaves loadnote0,loadnum1,loadnum3,loadnum4,loadnum5,loadnum8
			KillDataFolder $str
		Endif
	Endfor
	cd cdf
End


Function ESM_sekisan(int)
	string int 
	make/O dumm_MCD
	String wvname_MCD = int +"*MCD"
	String list = wavelist(wvname_MCD,";",""); list = SortList(list, ";", 16)
	Variable num=ItemsInList(list), i
	For(i=0; i<num; i+=1)
		String name_MCD=StringFromList(i, list)
		wave wave_MCD=$name_MCD
		variable size=dimsize(wave_MCD,0)
		redimension/N=(size) dumm_MCD
		dumm_MCD = dumm_MCD +wave_MCD
		//copyscales wave_MCD, dumm_MCD
	Endfor
	dumm_MCD = dumm_MCD/num
	duplicate/O dumm_MCD $int +"_MCD_M"
	killwaves dumm_MCD

	make/O dumm_xas
	String wvname_xas = int +"*xas"
	String list_xas = wavelist(wvname_xas,";",""); list = SortList(list_xas, ";", 16)
	Variable num_xas=ItemsInList(list_xas), j
	For(j=0; j<num_xas; j+=1)
		String name_xas=StringFromList(j, list_xas)
		wave wave_xas=$name_xas
		variable size_xas=dimsize(wave_xas,0)
		redimension/N=(size_xas) dumm_xas
		dumm_xas = dumm_xas +wave_xas
		//copyscales wave_MCD, dumm_MCD
	Endfor
	dumm_xas = dumm_xas/num
	duplicate/O dumm_xas $int +"_xas_M"
	killwaves dumm_xas

end


////////////


