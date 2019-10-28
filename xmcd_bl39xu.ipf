#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//=========================================================
macro LoadMCD(path, fname, wnini)		//偏光変調MCDデータファイルを読み込むマクロ
string path fname, wnini
// path: ファイルのあるディレクトリのパス文字列 ("" ならばファイルダイアログ)
// fname: ファイルネーム ("" ならばファイルダイアログ)
// wnini: wave名の共通文字列

	variable a = 5.4297094		// Si lattice constant at LN2 temperature,  in Angstrom
	variable h = 1, k = 1, l = 1

	string ene = wnini + "_ene"
	string mcd = wnini + "_mcd"
	string xas = wnini + "_xas"
	string theta = wnini + "_theta"
	string ene_meas = wnini + "_eneMeas"
	
	variable eneCol = 0,  thetaCol = 1, mcdCol = 6, xasCol = 7
	
	LoadWave/Q/G/D/N=wave/O /P=path fname
	duplicate /O $StringFromList(eneCol, S_waveNames), $ene
	duplicate /O $StringFromList(thetaCol, S_waveNames), $theta
	duplicate /O $StringFromList(mcdCol, S_waveNames), $mcd
	duplicate /O $StringFromList(xasCol, S_waveNames), $xas
	
	Sort  $ene, $ene, $theta, $mcd, $xas
	SetScale/I x $ene[0]*1000,$ene[numpnts($ene)-1]*1000,"eV", $ene, $mcd, $xas
	
	KillLoadWaves(S_waveNames)

	duplicate /O $theta, $ene_meas
	$ene_meas =  theta_to_E($theta, a, h, k, l)
end

 
 
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

Menu "Macros"
	"MCD: load folder", load_folder()
	"MCD: load file", load_file()
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





function KillLoadWaves(wnlist)
string wnlist
	variable i
	
	for(i = 0; i < ItemsInList(wnlist); i += 1)
		killwaves $StringFromList(i, wnlist)
	endfor
end

//=========================================================
// CT32-01EによるXMCDのsumデータファイルを読み込むマクロ (2019.4.25)
// dead time 補正も行う
// 使わない素子をマスク可能
// ESM測定のsumデータも読み込み可能

Constant Flag_16ch_only = 1		// 32chのうち、16chの分のデータしか保存されていないファイルに対しては、この定数を 1とすること。

macro LoadMCD_CT32_sum(path, fname, wnini, fluo_SCA, total_SCA, deadTime, SDD_ElementMask, ESM_flag)
string path, fname, wnini
variable fluo_SCA, total_SCA	// 目的の蛍光のSCA ch, totalのSCA ch (1～4)
string deadTime		// 4素子分のdeadTimeのwave名。単位: 秒
string SDD_ElementMask	// 4素子SDDのどの素子のデータを使うかの、マスクのための文字列。"1111"...4素子全て使用。"1101" ... 3素子目(ch2)不使用
variable ESM_flag	// 0: XMCD, 1: ESM

	variable wk
	if (cmpstr(wnini,"")==0)
		wk = strsearch(fname, ".", strlen(fname),1)
		if (wk>=0)
			wnini = fname[0, wk-1]
		else 
			wnini = fname
		endif
	endif

	string ene = wnini + "_ene"
	string mag = wnini + "_mag"
	string xas_R = wnini + "_xas_R"
	string xasR_Corr = wnini + "_xasR_Corr"
	string xas_L = wnini + "_xas_L"
	string xasL_Corr = wnini + "_xasL_Corr"
	string mcd_Corr = wnini + "_mcdCorr"
	string xasAve_Corr = wnini + "_xasAveCorr"

	LoadWave/A/Q/O/G/D/W/P=$path fname
	Make /O/T/N=1 wNames
	
	if (ESM_flag==0)
		wNames[0] = "Energy_keV"
	else
		wNames[0] =  "MagField"
	endif

	if (Flag_16ch_only==1)
		wNames[1] = {"PZT_R", "Time_R"}
		wNames[3] = {"I0_R"}
		wNames[4] = {"SCA1_ch0_R", "SCA1_ch1_R","SCA1_ch2_R","SCA1_ch3_R"}
		wNames[8] = {"SCA2_ch0_R", "SCA2_ch1_R","SCA2_ch2_R","SCA2_ch3_R"}
		wNames[12] = {"SCA3_ch0_R", "SCA3_ch1_R","SCA3_ch2_R","SCA3_ch3_R"}
		wNames[16] = {"SCA4_ch0_R", "SCA4_ch1_R","SCA4_ch2_R","SCA4_ch3_R"}
		wNames[20] = {"PZT_L", "Time_L"}
		wNames[22] = {"I0_L"}
		wNames[23] = {"SCA1_ch0_L", "SCA1_ch1_L","SCA1_ch2_L","SCA1_ch3_L"}
		wNames[27] = {"SCA2_ch0_L", "SCA2_ch1_L","SCA2_ch2_L","SCA2_ch3_L"}
		wNames[31] = {"SCA3_ch0_L", "SCA3_ch1_L","SCA3_ch2_L","SCA3_ch3_L"}
		wNames[35] = {"SCA4_ch0_L", "SCA4_ch1_L","SCA4_ch2_L","SCA4_ch3_L"}
		wNames[39] = {"col39"}
		wNames[40] = {"col40", "col41", "col42", "col43", "col44", "col45", "col46", "col47", "col48", "col49"}
		wNames[50] = {"col50", "col51", "col52", "col53", "col54", "col55", "col56"}
	else
		wNames[1] = {"PZT_R", "Time_R"}
		wNames[3] = {"I0_R"}
		wNames[4] = {"SCA1_ch0_R", "SCA1_ch1_R","SCA1_ch2_R","SCA1_ch3_R"}
		wNames[8] = {"SCA2_ch0_R", "SCA2_ch1_R","SCA2_ch2_R","SCA2_ch3_R"}
		wNames[12] = {"SCA3_ch0_R", "SCA3_ch1_R","SCA3_ch2_R","SCA3_ch3_R"}
		wNames[16] = {"SCA4_ch0_R", "SCA4_ch1_R","SCA4_ch2_R","SCA4_ch3_R"}
		wNames[20] = {"col20", "col21","col22","col23","col24","col25","col26","col27","col28","col29"}
		wNames[30] = {"col30", "col31","col32","col33","col34","col35"}
		wNames[36] = {"PZT_L", "Time_L"}
		wNames[38] = {"I0_L"}
		wNames[39] = {"SCA1_ch0_L", "SCA1_ch1_L","SCA1_ch2_L","SCA1_ch3_L"}
		wNames[43] = {"SCA2_ch0_L", "SCA2_ch1_L","SCA2_ch2_L","SCA2_ch3_L"}
		wNames[47] = {"SCA3_ch0_L", "SCA3_ch1_L","SCA3_ch2_L","SCA3_ch3_L"}
		wNames[51] = {"SCA4_ch0_L", "SCA4_ch1_L","SCA4_ch2_L","SCA4_ch3_L"}
		wNames[55] = {"col55", "col56", "col57", "col58", "col59"}
		wNames[60] = {"col60", "col61", "col62", "col63", "col64", "col65", "col66", "col67", "col68", "col69"}
		wNames[70] = {"col70", "col71", "col72"}
	endif
	
	variable i = 0
	do 
//	print i, StringFromList(i, S_waveNames), wNames[i]
		duplicate /O  $StringFromList(i, S_waveNames), $wNames[i]
		i += 1
	while (i<numpnts(wNames))
	KillLoadWaves (S_waveNames)

	if (ESM_flag==0)
		duplicate /O Energy_keV, $ene
	else
		duplicate /O MagField, $mag
	endif

	variable SDD_elementNum = 4
	string If_R, Total_R, If_L, Total_L

	duplicate /O I0_R, $xas_R, $xasR_Corr
	duplicate /O I0_L, $xas_L, $xasL_Corr	

	i = 0
	$xas_R = 0; $xasR_Corr = 0; $xas_L = 0; $xasL_Corr = 0
	do
		if (cmpstr(SDD_ElementMask[i], "1")==0)
			If_R =    "SCA" + num2str(fluo_SCA) +"_ch" + num2str(i)+"_R"
			Total_R = "SCA" + num2str(total_SCA)+"_ch" + num2str(i)+"_R"
			If_L =    "SCA" + num2str(fluo_SCA) +"_ch" + num2str(i)+"_L"
			Total_L = "SCA" + num2str(total_SCA)+"_ch" + num2str(i)+"_L"

			$xas_R += $If_R
			$xasR_Corr +=  deadTimeCorr($If_R, $Total_R, Time_R, $deadTime[i])
			$xas_L += $If_L
			$xasL_Corr +=  deadTimeCorr($If_L, $Total_L, Time_L, $deadTime[i])
		endif
		i += 1
	while(i<SDD_elementNum)

	$xas_R /= I0_R
	$xasR_Corr /= I0_R
	$xas_L /= I0_L
	$xasL_Corr /= I0_L
			
	duplicate /O $xasR_Corr, $mcd_Corr, $xasAve_Corr
	$mcd_Corr = $xasR_Corr - $xasL_Corr
	$xasAve_Corr = $xasR_Corr/2 + $xasL_Corr/2
	
	if (ESM_flag==0)		// XMCDの場合、エネルギーにしたがってデータをソートする
		Sort  $ene, $ene, $xas_R, $xasR_Corr, $xas_L, $xasL_Corr, $mcd_Corr, $xasAve_Corr
		SetScale/I x $ene[0]*1000,$ene[numpnts($ene)-1]*1000,"eV", $ene, $xas_R, $xasR_Corr, $xas_L, $xasL_Corr, $mcd_Corr, $xasAve_Corr
	endif
	
	// 生データをサブフォルダーに移動
	string subFolder = wnini + "_rawData"
	NewDataFolder /O $subFolder
	string s
	i = 0
	do 
		s = ":'" + subFolder + "':'" + wNames[i] + "'"
		duplicate /O  $wNames[i], $s
		Killwaves $wNames[i]
		i += 1
	while (i < numpnts(wNames))

End

//=========================================================
// 蛍光Ｘ線検出器 (SDD) の不感時間の補正を行う
function deadTimeCorr(N_fluo, N_tot, countTime, tau)
variable N_fluo, N_tot, countTime, tau

	return N_fluo/(1-N_tot*tau/countTime)
end

function theta_to_E(theta, a, h, k, l)		// monochromator angle to X-ray energy
variable theta	// Bragg angle in deg.
variable a			// lattice constant in Angstrom
variable h, k, l	

	return  lambda_to_E(wavelength_at_Bragg(theta, a, h, k, l))
end

function E_to_theta(ene, a, h, k, l)		// X-ray energy to mono. angle
	variable ene	// X-ray energy in keV
	variable a			// lattice constant in Angstrom
	variable h, k, l	
	variable d = a/sqrt(h^2 + k^2 + l^2)
	return asin(E_to_lambda(ene)/(2*d))*180/pi		// in deg
end

function wavelength_at_Bragg(theta, a, h, k, l)
variable theta 		// crystal angle in de.
variable a				// lattice constant in Angstrom
variable h, k, l

	variable d = a/sqrt(h^2 + k^2 + l^2)
	return 2*d*sin(theta*pi/180)	// X-ray wavelength in Angstrom
end

function lambda_to_E(lambda)		// wavelength (A) to photon energy (keV)
variable lambda		// in Angstrom
	variable h = 6.6260755e-34
	variable c = 2.99792458e8
	variable qe = 1.60217733e-19
	
	return h*c/(qe*lambda*1e-10)*1e-3	// in keV
end

function E_to_lambda(ene)		// photon energy (keV) to wavelength (A)
variable ene		// in keV
	variable h = 6.6260755e-34
	variable c = 2.99792458e8
	variable qe = 1.60217733e-19
	
	return h*c/(qe*ene*1e3)*1e10	// in Angstrom
end
