struct s_NOD *__cdecl sub_10008DC0(int a1, int a2, float *a3, int a4)
{
  int v4; // ebx
  void *v5; // eax
  int v6; // ecx
  int v7; // edi
  int v8; // ecx
  int v9; // ecx
  SIZE_T v10; // esi
  SIZE_T v11; // edx
  SIZE_T v12; // ecx
  float *v13; // eax
  double v14; // st6
  int v15; // edi
  int v16; // eax
  int v17; // ecx
  float v18; // esi
  LPVOID v19; // eax
  float v20; // ecx
  void *v21; // esi
  void *v22; // eax
  unsigned int v23; // edx
  SIZE_T v24; // ecx
  _DWORD *v25; // eax
  int v26; // edi
  int v27; // edx
  int v28; // ecx
  int v29; // eax
  int v30; // edi
  int v31; // edx
  int v32; // ecx
  int v33; // eax
  int *v34; // eax
  float v35; // esi
  int v36; // ecx
  float v37; // edi
  float v38; // eax
  const void *v39; // edi
  float v40; // ecx
  float v41; // eax
  void *v42; // edi
  void *v43; // eax
  int v44; // eax
  _DWORD *v45; // eax
  int v46; // edx
  int v47; // ecx
  int v48; // edi
  float v49; // eax
  int v50; // ecx
  LPVOID v51; // eax
  float v52; // ecx
  void *v53; // edi
  float v54; // ecx
  int v55; // eax
  unsigned int v56; // edx
  unsigned int v57; // eax
  char *v58; // edx
  char *v59; // edx
  char v60; // al
  int i; // edi
  struct s_NOD *v62; // esi
  unsigned int v63; // ecx
  int v64; // edi
  bool v65; // zf
  unsigned int v66; // esi
  int v67; // eax
  __int64 v68; // rax
  char v69; // cl
  int v70; // eax
  float v71; // eax
  unsigned int v72; // edi
  void *v73; // eax
  int v74; // ecx
  unsigned int v75; // eax
  int v76; // ecx
  int v77; // eax
  int v78; // eax
  float *v79; // edi
  double v80; // st7
  float *v81; // edi
  float v82; // edx
  double v83; // st7
  double v84; // st6
  float *v85; // edi
  __int64 v86; // kr48_8
  float v87; // edx
  double v88; // st7
  double v89; // st6
  double v90; // st4
  float *v91; // edi
  float v92; // ecx
  double v93; // st7
  double v94; // st6
  double v95; // st4
  float v96; // eax
  float v97; // edx
  int v98; // eax
  float v99; // ecx
  float v100; // edx
  float v101; // ecx
  float v102; // esi
  void *v103; // eax
  unsigned int v104; // ecx
  float v105; // esi
  float v106; // eax
  int v107; // edi
  char *v108; // eax
  float v109; // esi
  int v110; // eax
  void *v111; // eax
  char **v112; // esi
  char *v113; // edi
  const char **v114; // ebx
  int v115; // eax
  const char *v116; // edi
  const char *v117; // edi
  int *v118; // eax
  int v119; // ecx
  const char *v120; // edi
  const char *v121; // edi
  const char *v122; // edi
  const char *v123; // edi
  LPVOID *v124; // edi
  float v125; // ebx
  float v126; // eax
  float v127; // edx
  int v128; // eax
  float v129; // esi
  float v130; // ecx
  int v131; // eax
  unsigned int v132; // edx
  int v133; // eax
  SIZE_T v134; // ecx
  float v135; // esi
  int v136; // eax
  float v137; // edx
  float v138; // esi
  float v139; // eax
  SIZE_T v140; // ecx
  float v141; // eax
  SIZE_T v142; // edx
  SIZE_T v143; // kr0C_4
  float v144; // eax
  SIZE_T v145; // edx
  SIZE_T v146; // kr10_4
  _DWORD *v147; // edx
  __int16 v148; // eax^2
  int v149; // ecx
  float v150; // ecx
  int v151; // eax
  float v152; // esi
  float v153; // edx
  int v154; // eax
  int v155; // esi
  int v156; // eax
  SIZE_T v157; // esi
  int v158; // eax
  float v159; // esi
  float v160; // eax
  unsigned int v161; // ecx
  float v162; // eax
  void *v163; // esi
  double v164; // st7
  float v165; // esi
  int v166; // edi
  SIZE_T v167; // edi
  _DWORD **v168; // edi
  _DWORD *v169; // ebp
  int v170; // eax
  int v171; // edx
  void *v172; // edi
  int v173; // eax
  int v174; // eax
  int v175; // eax
  int v176; // eax
  int v177; // edi
  _DWORD *v178; // ecx
  int v179; // edx
  _DWORD *v180; // ecx
  int v181; // edx
  int v182; // ebx
  const void *v183; // eax
  float v184; // ecx
  float v185; // edx
  void *v186; // edi
  void *v187; // edi
  char *v188; // ebx
  int v189; // edx
  int v190; // ebp
  int v191; // eax
  unsigned int j; // eax
  _DWORD *v193; // ecx
  float *v194; // eax
  double v195; // st7
  double v196; // st6
  double v197; // st5
  long double v198; // st4
  long double v199; // st3
  long double v200; // st2
  double v201; // st7
  double v202; // st7
  void *v203; // eax
  void *v204; // edi
  const void *v205; // esi
  double v206; // st7
  double v207; // st6
  double v208; // st5
  double v209; // st4
  double v210; // st3
  double v211; // st2
  long double v212; // st1
  float v213; // eax
  double v214; // st3
  const void *v215; // esi
  void **v216; // ebp
  _DWORD **v217; // esi
  _DWORD *v218; // ecx
  unsigned int v219; // eax
  void ***v220; // edx
  _DWORD *v221; // edx
  int v222; // ecx
  void *v223; // edi
  int v224; // eax
  int v225; // eax
  int v226; // eax
  unsigned int v227; // esi
  int *v228; // edi
  int v229; // eax
  char v230; // al
  _DWORD *v231; // ebx
  unsigned int v232; // edi
  float v233; // esi
  int v234; // edx
  unsigned int v235; // edi
  int v236; // esi
  struct s_NOD *v237; // edi
  int v238; // eax
  int v239; // eax
  int v240; // eax
  struct s_NOD *v241; // esi
  int v242; // ebx
  int v243; // ebp
  LPVOID v244; // edi
  LPVOID v245; // edi
  char v247; // [esp-80h] [ebp-864h] BYREF
  int v248; // [esp-7Ch] [ebp-860h]
  int v249; // [esp-78h] [ebp-85Ch]
  int v250; // [esp-74h] [ebp-858h]
  int v251; // [esp-70h] [ebp-854h]
  int v252; // [esp-6Ch] [ebp-850h]
  int v253; // [esp-68h] [ebp-84Ch]
  int v254; // [esp-64h] [ebp-848h]
  int v255; // [esp-60h] [ebp-844h]
  int v256; // [esp-5Ch] [ebp-840h]
  int v257; // [esp-58h] [ebp-83Ch]
  int v258; // [esp-54h] [ebp-838h]
  int v259; // [esp-50h] [ebp-834h]
  int v260; // [esp-4Ch] [ebp-830h]
  int v261; // [esp-48h] [ebp-82Ch]
  int v262; // [esp-44h] [ebp-828h]
  _QWORD v263[8]; // [esp-40h] [ebp-824h] BYREF
  float v264; // [esp+10h] [ebp-7D4h]
  float v265; // [esp+14h] [ebp-7D0h]
  SIZE_T dwBytes; // [esp+18h] [ebp-7CCh]
  void *v267; // [esp+1Ch] [ebp-7C8h]
  float v268; // [esp+20h] [ebp-7C4h]
  float v269; // [esp+24h] [ebp-7C0h]
  __int64 v270; // [esp+28h] [ebp-7BCh]
  float v271; // [esp+30h] [ebp-7B4h]
  float v272; // [esp+34h] [ebp-7B0h]
  float v273; // [esp+38h] [ebp-7ACh]
  float v274; // [esp+3Ch] [ebp-7A8h]
  float v275; // [esp+40h] [ebp-7A4h]
  float v276; // [esp+44h] [ebp-7A0h]
  __int64 v277; // [esp+48h] [ebp-79Ch]
  float v278; // [esp+50h] [ebp-794h]
  int v279; // [esp+54h] [ebp-790h] BYREF
  struct s_NOD *v280; // [esp+58h] [ebp-78Ch]
  unsigned int v281; // [esp+5Ch] [ebp-788h] BYREF
  __int64 v282; // [esp+60h] [ebp-784h]
  float v283; // [esp+68h] [ebp-77Ch]
  float v284[16]; // [esp+6Ch] [ebp-778h] BYREF
  int v285; // [esp+ACh] [ebp-738h] BYREF
  _DWORD v286[4]; // [esp+B0h] [ebp-734h] BYREF
  char v287[200]; // [esp+C0h] [ebp-724h] BYREF
  char v288[128]; // [esp+188h] [ebp-65Ch] BYREF
  char Buffer[200]; // [esp+208h] [ebp-5DCh] BYREF
  char v290[200]; // [esp+2D0h] [ebp-514h] BYREF
  char v291[200]; // [esp+398h] [ebp-44Ch] BYREF
  char v292[200]; // [esp+460h] [ebp-384h] BYREF
  float v293; // [esp+528h] [ebp-2BCh] BYREF
  char v294; // [esp+52Ch] [ebp-2B8h]
  char v295[256]; // [esp+624h] [ebp-1C0h] BYREF
  char v296[64]; // [esp+724h] [ebp-C0h] BYREF
  char v297[64]; // [esp+764h] [ebp-80h] BYREF
  char v298[64]; // [esp+7A4h] [ebp-40h] BYREF

  v4 = a2;
  v5 = *(void **)(*(_DWORD *)a3 + a2);
  v6 = *(_DWORD *)a3 + 4;
  *(_DWORD *)a3 = v6;
  v7 = *(_DWORD *)(v6 + a2);
  v6 += 4;
  *(_DWORD *)a3 = v6;
  v8 = v6 + v7 - 8;
  v280 = 0;
  v272 = *(float *)&v5;
  v276 = *(float *)&v8;
  if ( v5 == (void *)112 )
  {
    *a3 = *(float *)&v8;
    v5 = *(void **)(v8 + a2);
    v9 = v8 + 4;
    *(_DWORD *)a3 = v9;
    v7 = *(_DWORD *)(v9 + a2);
    v9 += 4;
    *(_DWORD *)a3 = v9;
    v272 = *(float *)&v5;
    LODWORD(v276) = v9 + v7 - 8;
  }
  if ( (unsigned int)v5 <= 0x36 )
  {
    if ( v5 == (void *)54 )
    {
      dword_10240EAC = *(_DWORD *)(*(_DWORD *)a3 + a2);
      *(_DWORD *)a3 += 4;
    }
    else
    {
      switch ( (unsigned int)v5 )
      {
        case 1u:
          goto LABEL_56;
        case 0x30u:
          dword_10240EA8 = *(_DWORD *)(*(_DWORD *)a3 + a2);
          *(_DWORD *)a3 += 4;
          if ( dword_10240EA8 )
          {
            dword_10240EB4 = HeapAlloc(hHeap, 0, 28 * dword_10240EA8);
            memset(dword_10240EB4, 0, 28 * dword_10240EA8);
          }
          else
          {
            dword_10240EB4 = 0;
          }
          dword_1018F08C = -1;
          break;
        case 0x31u:
          ++dword_1018F08C;
          v44 = *(_DWORD *)(*(_DWORD *)a3 + a2);
          *(_DWORD *)a3 += 4;
          if ( v44 == -1 )
            *((_DWORD *)dword_10240EB4 + 7 * dword_1018F08C) = 0;
          else
            *((_DWORD *)dword_10240EB4 + 7 * dword_1018F08C) = dword_1018CEE4[0] + 120 * v44;
          break;
        case 0x32u:
          v45 = (char *)dword_10240EB4 + 28 * dword_1018F08C;
          v45[1] = *(_DWORD *)(*(_DWORD *)a3 + a2);
          v46 = *(_DWORD *)a3 + 4;
          *(_DWORD *)a3 = v46;
          v45[3] = *(_DWORD *)(v46 + a2);
          v47 = *(_DWORD *)a3 + 4;
          *(_DWORD *)a3 = v47;
          v45[2] = *(_DWORD *)(v47 + a2);
          v48 = *(_DWORD *)a3 + 4;
          *(_DWORD *)a3 = v48;
          if ( v45[3] * v45[1] )
            *(_DWORD *)a3 += sub_10008B20(v45, (_DWORD *)(a2 + v48));
          else
            v45[5] = 0;
          break;
        case 0x33u:
          LODWORD(v49) = (char *)dword_10240EB4 + 28 * dword_1018F08C;
          *(_DWORD *)(LODWORD(v49) + 16) = *(_DWORD *)(*(_DWORD *)a3 + a2);
          *(_DWORD *)a3 += 4;
          v50 = *(_DWORD *)(LODWORD(v49) + 16);
          v265 = v49;
          if ( v50 )
          {
            v51 = HeapAlloc(hHeap, 0, 12 * v50);
            v52 = v265;
            *(_DWORD *)(LODWORD(v265) + 24) = v51;
            v53 = v51;
            v49 = v265;
            qmemcpy(v53, (const void *)(a2 + *(_DWORD *)a3), 12 * *(_DWORD *)(LODWORD(v52) + 16));
          }
          else
          {
            *(_DWORD *)(LODWORD(v49) + 24) = 0;
          }
          *(_DWORD *)a3 += 12 * *(_DWORD *)(LODWORD(v49) + 16);
          break;
        case 0x34u:
          v10 = *(SIZE_T *)(*(_DWORD *)a3 + a2);
          *(_DWORD *)a3 += 4;
          dwBytes = v10;
          if ( dword_10240EB0 )
          {
            HeapFree(hHeap, 0, dword_10240EB0);
            dword_10240EB0 = 0;
          }
          if ( *(float *)&v10 != 0.0 )
          {
            dword_10240EB0 = (char *)HeapAlloc(hHeap, 0, dwBytes);
            v11 = dwBytes;
            qmemcpy(dword_10240EB0, (const void *)(a2 + *(_DWORD *)a3), dwBytes);
            v12 = dwBytes + *(_DWORD *)a3;
            HIDWORD(v263[7]) = 0;
            *(_DWORD *)a3 = v12;
            v13 = (float *)INI_read(dword_10240EB0, v11, aClipdist, asc_10173654, &v281, SHIDWORD(v263[7]));
            if ( v281 == 1 )
            {
              v14 = *v13 * *v13;
              if ( a1 )
                *(float *)(a1 + 92) = v14;
              else
                flt_10240EE0 = v14;
            }
            INI_release(v13);
            if ( a1 )
            {
              v15 = a1;
              v16 = *(_DWORD *)(a1 + 124);
              if ( !v16 || v16 == 6 )
              {
                *(float *)&v267 = COERCE_FLOAT(INI_read(dword_10240EB0, dwBytes, aLod, asc_10173654, &v281, 0));
                if ( v281 > 1 )
                {
                  v17 = *(_DWORD *)(a1 + 88) | 0x1000000;
                  HIDWORD(v263[7]) = 24;
                  *(_DWORD *)(a1 + 124) = 18;
                  *(_DWORD *)(a1 + 88) = v17;
                  v18 = COERCE_FLOAT(HeapAlloc(hHeap, 0, HIDWORD(v263[7])));
                  *(_DWORD *)LODWORD(v18) = a1;
                  *(_DWORD *)(LODWORD(v18) + 20) = 1065353216;
                  *(_DWORD *)(LODWORD(v18) + 16) = 1;
                  *(_DWORD *)(LODWORD(v18) + 4) = v281;
                  v265 = v18;
                  if ( v281 )
                  {
                    v19 = HeapAlloc(hHeap, 0, 4 * v281);
                    v20 = v18;
                    v21 = v267;
                    *(_DWORD *)(LODWORD(v20) + 8) = v19;
                    qmemcpy(v19, v21, 4 * *(_DWORD *)(LODWORD(v20) + 4));
                    v18 = v265;
                    v22 = HeapAlloc(hHeap, 0, 4 * *(_DWORD *)(LODWORD(v265) + 4));
                    v23 = 4 * *(_DWORD *)(LODWORD(v265) + 4);
                    *(_DWORD *)(LODWORD(v265) + 12) = v22;
                    memset(v22, 0, v23);
                    v15 = a1;
                  }
                  else
                  {
                    *(_DWORD *)(LODWORD(v18) + 8) = 0;
                    *(_DWORD *)(LODWORD(v18) + 12) = 0;
                  }
                  v24 = dwBytes;
                  HIDWORD(v263[7]) = 0;
                  LODWORD(v263[7]) = &v281;
                  HIDWORD(v263[6]) = aI;
                  LODWORD(v263[6]) = aLastlodalpha;
                  *(float *)(v15 + 128) = v18;
                  v25 = INI_read(
                          dword_10240EB0,
                          v24,
                          (char *)v263[6],
                          (char *)HIDWORD(v263[6]),
                          (unsigned int *)v263[7],
                          SHIDWORD(v263[7]));
                  if ( v281 == 1 )
                    *(_DWORD *)(LODWORD(v18) + 16) = *v25 != 0;
                  INI_release(v25);
                }
                INI_release(v267);
              }
            }
          }
          break;
        case 0x35u:
          dword_10240EB8 = 1;
          flt_10240EBC = *(float *)(*(_DWORD *)a3 + a2);
          v26 = *(_DWORD *)a3 + 4;
          *(_DWORD *)a3 = v26;
          flt_10240EC0 = *(float *)(v26 + a2);
          v27 = *(_DWORD *)a3 + 4;
          *(_DWORD *)a3 = v27;
          flt_10240EC4 = *(float *)(v27 + a2);
          v28 = *(_DWORD *)a3 + 4;
          *(_DWORD *)a3 = v28;
          flt_10240EC8 = *(float *)(v28 + a2);
          v29 = *(_DWORD *)a3 + 4;
          *(_DWORD *)a3 = v29;
          flt_10240ECC = *(float *)(v29 + a2);
          v30 = *(_DWORD *)a3 + 4;
          *(_DWORD *)a3 = v30;
          flt_10240ED0 = *(float *)(v30 + a2);
          v31 = *(_DWORD *)a3 + 4;
          *(_DWORD *)a3 = v31;
          flt_10240ED4 = *(float *)(v31 + a2);
          v32 = *(_DWORD *)a3 + 4;
          *(_DWORD *)a3 = v32;
          flt_10240ED8 = *(float *)(v32 + a2);
          v33 = *(_DWORD *)a3 + 4;
          *(_DWORD *)a3 = v33;
          flt_10240EDC = *(float *)(v33 + a2);
          *(_DWORD *)a3 += 4;
          memset(&dword_10240EE4, 0, 0x40u);
          v34 = (int *)(a2 + *(_DWORD *)a3);
          dword_10240EE4 = *v34;
          dword_10240EE8 = v34[1];
          dword_10240EEC = v34[2];
          dword_10240EF0 = v34[3];
          dword_10240EF4 = v34[4];
          dword_10240EF8 = v34[5];
          dword_10240EFC = v34[6];
          dword_10240F00 = v34[7];
          dword_10240F04 = v34[8];
          dword_10240F08 = v34[9];
          dword_10240F0C = v34[10];
          dword_10240F10 = v34[11];
          dword_10240F14 = v34[12];
          dword_10240F18 = v34[13];
          dword_10240F1C = v34[14];
          dword_10240F20 = v34[15];
          *(_DWORD *)a3 += 64;
          if ( a1 )
          {
            v35 = COERCE_FLOAT(HeapAlloc(hHeap, 0, 0x6Cu));
            v36 = *(_DWORD *)a1;
            *(float *)(a1 + 4) = v35;
            v37 = *(float *)(v36 + 4);
            v269 = v35;
            v264 = v37;
            if ( v37 != 0.0 )
            {
              if ( v35 != NAN )
              {
                v267 = *(void **)(LODWORD(v37) + 4);
                HIDWORD(v263[7]) = 4 * ((_DWORD)v267 + 1);
                *(_DWORD *)(LODWORD(v37) + 4) = (char *)v267 + 1;
                v38 = COERCE_FLOAT(HeapAlloc(hHeap, 0, HIDWORD(v263[7])));
                v39 = *(const void **)(LODWORD(v37) + 8);
                v265 = v38;
                if ( v39 )
                {
                  qmemcpy((void *)LODWORD(v38), v39, 4 * (_DWORD)v267);
                  if ( *(_DWORD *)(LODWORD(v264) + 8) )
                  {
                    HeapFree(hHeap, 0, *(LPVOID *)(LODWORD(v264) + 8));
                    *(_DWORD *)(LODWORD(v264) + 8) = 0;
                  }
                }
                v40 = v265;
                v41 = v269;
                v35 = v269;
                v37 = v264;
                *(float *)(LODWORD(v264) + 8) = v265;
                *(_DWORD *)(LODWORD(v40) + 4 * (_DWORD)v267) = LODWORD(v41) + 100;
              }
              ++*(_DWORD *)(LODWORD(v37) + 96);
            }
            memset((void *)LODWORD(v35), 0, 0x6Cu);
            *(float *)LODWORD(v35) = v264;
            HIDWORD(v263[7]) = 64;
            *(_DWORD *)(LODWORD(v35) + 96) = 1;
            *(_DWORD *)(LODWORD(v35) + 4) = 0;
            *(_DWORD *)(LODWORD(v35) + 8) = 0;
            *(_DWORD *)(LODWORD(v35) + 104) = 0;
            *(_DWORD *)(LODWORD(v35) + 100) = 1;
            *(_DWORD *)(LODWORD(v35) + 92) = 0;
            v42 = HeapAlloc(hHeap, 0, HIDWORD(v263[7]));
            *(_DWORD *)(LODWORD(v35) + 104) = v42;
            memset(v42, 0, 0x40u);
            *(_DWORD *)(*(_DWORD *)(LODWORD(v35) + 104) + 60) = 1065353216;
            *(_DWORD *)(*(_DWORD *)(LODWORD(v35) + 104) + 40) = 1065353216;
            *(_DWORD *)(*(_DWORD *)(LODWORD(v35) + 104) + 20) = 1065353216;
            **(_DWORD **)(LODWORD(v35) + 104) = 1065353216;
            memset((void *)(LODWORD(v35) + 12), 0, 0x40u);
            *(_DWORD *)(LODWORD(v35) + 12) = 1065353216;
            *(_DWORD *)(LODWORD(v35) + 100) |= 0xCu;
            *(_DWORD *)(LODWORD(v35) + 32) = 1065353216;
            *(_DWORD *)(LODWORD(v35) + 52) = 1065353216;
            *(_DWORD *)(LODWORD(v35) + 72) = 1065353216;
            if ( *(_DWORD *)a1 && *(_DWORD *)(*(_DWORD *)a1 + 4) )
            {
              qmemcpy(v263, &dword_10240EE4, sizeof(v263));
              v43 = sub_100087B0(*(_DWORD *)(*(_DWORD *)a1 + 4), v297);
              sub_10025690(&v247, v43);
              qmemcpy(
                *(void **)(*(_DWORD *)(a1 + 4) + 104),
                sub_10005920(
                  v296,
                  v247,
                  v248,
                  v249,
                  v250,
                  v251,
                  v252,
                  v253,
                  v254,
                  v255,
                  v256,
                  v257,
                  v258,
                  v259,
                  v260,
                  v261,
                  v262,
                  v263[0]),
                0x40u);
            }
            else
            {
              qmemcpy(*(void **)(*(_DWORD *)(a1 + 4) + 104), &dword_10240EE4, 0x40u);
            }
          }
          break;
        default:
          goto LABEL_118;
      }
    }
    goto LABEL_272;
  }
  if ( (unsigned int)v5 > 0x51 )
  {
    if ( v5 == (void *)4096 )
    {
      v166 = *(_DWORD *)(*(_DWORD *)a3 + a2);
      *(_DWORD *)a3 += 4;
      if ( dword_1018C98C )
      {
        sub_10008160((LPVOID *)&dword_1018C98C);
        dword_1018C98C = 0;
      }
      dword_1018C98C = (int)HeapAlloc(hHeap, 0, 8u);
      *(_DWORD *)dword_1018C98C = v166;
      if ( v166 )
      {
        v167 = 120 * v166;
        *(_DWORD *)(dword_1018C98C + 4) = HeapAlloc(hHeap, 0, v167);
        memset(*(void **)(dword_1018C98C + 4), 0, v167);
      }
      else
      {
        *(_DWORD *)(dword_1018C98C + 4) = 0;
      }
      dword_1018CEE4[0] = *(_DWORD *)(dword_1018C98C + 4);
      dword_1018F088 = 0;
      *(_DWORD *)(a1 + 124) = 0;
      goto LABEL_272;
    }
    if ( v5 == (void *)4097 )
    {
      v126 = *a3;
      if ( dword_1018C974 == 875573296 )
      {
        v150 = *(float *)(LODWORD(v126) + a2);
        v151 = LODWORD(v126) + 4;
        *(_DWORD *)a3 = v151;
        v152 = *(float *)(v151 + a2);
        v151 += 4;
        *(_DWORD *)a3 = v151;
        v153 = *(float *)(v151 + a2);
        v265 = v150;
        v154 = v151 + 4;
        v268 = v152;
        v264 = v153;
        *(_DWORD *)a3 = v154;
        v293 = v152;
        v294 = 0;
        v287[0] = 0;
        Buffer[0] = 0;
        if ( (LOBYTE(v153) & 1) != 0 )
        {
          v155 = *(_DWORD *)(v154 + a2);
          v156 = v154 + 4;
          *(_DWORD *)a3 = v156;
          v279 = v155;
          v267 = *(void **)(v156 + a2);
          *(_DWORD *)a3 = v156 + 4;
        }
        if ( (LOBYTE(v153) & 2) != 0 )
        {
          v157 = *(SIZE_T *)(*(_DWORD *)a3 + a2);
          v158 = *(_DWORD *)a3 + 4;
          *(_DWORD *)a3 = v158;
          dwBytes = v157;
          v159 = *(float *)(v158 + a2);
          v158 += 4;
          *(_DWORD *)a3 = v158;
          *(float *)&v270 = *(float *)(v158 + a2);
          v269 = v159;
          *(_DWORD *)a3 = v158 + 4;
        }
        if ( (LOBYTE(v153) & 1) != 0 )
        {
          v160 = *a3;
          qmemcpy(Buffer, (const void *)(*(_DWORD *)a3 + a2), v279);
          v161 = v279;
          *(_DWORD *)a3 = v279 + LODWORD(v160);
          if ( v161 > 0x1E )
            COM_message("Texture name too long: %s", Buffer);
          COM_TXT_ConvertToSmallCaseString(Buffer);
          COM_TXT_CutFilenameExtension(Buffer);
          LODWORD(v264) &= ~1u;
          LOBYTE(v153) = LOBYTE(v264);
        }
        if ( (LOBYTE(v153) & 2) != 0 )
        {
          v162 = *a3;
          qmemcpy(v287, (const void *)(*(_DWORD *)a3 + a2), dwBytes);
          HIDWORD(v263[7]) = v287;
          *(_DWORD *)a3 = dwBytes + LODWORD(v162);
          COM_TXT_ConvertToSmallCaseString((char *)HIDWORD(v263[7]));
          COM_TXT_CutFilenameExtension(v287);
        }
        *(float *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088) = v265;
        LODWORD(v273) = *(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 8;
        strcpy((char *)LODWORD(v273), Buffer);
        v163 = v267;
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 64) = -1;
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 92) = v163;
        *(float *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 100) = v269;
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 4) = 0;
        if ( LOBYTE(v293) == 35 )
        {
          switch ( BYTE1(v293) )
          {
            case '0':
              *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 4) = 3;
              break;
            case '1':
              *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 4) = 1;
              break;
            case '2':
              *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 4) = 4;
              break;
            case '3':
              *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 4) = 2;
              break;
            case '4':
              *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 4) = 5;
              break;
            default:
              break;
          }
        }
        if ( v287[0] )
        {
          v164 = *(float *)&v270 * 100.0;
          *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 40) = HeapAlloc(
                                                                                       hHeap,
                                                                                       0,
                                                                                       strlen(v287) + 1);
          LODWORD(v273) = 15 * dword_1018F088;
          strcpy(*(char **)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 40), v287);
          *(float *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 88) = v164;
        }
        else
        {
          *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 40) = 0;
        }
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 72) = -1;
        v165 = v268;
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 68) = -1;
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 104) = LOWORD(v165);
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 108) = LOWORD(v165);
        *(_BYTE *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 112) = BYTE2(v165);
        *(_BYTE *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 113) = HIBYTE(v165);
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088++ + 56) = 0;
        if ( dword_1018F088 == *(_DWORD *)dword_1018C98C )
          LG(3u, aMaterialsListE);
      }
      else
      {
        v127 = *(float *)(LODWORD(v126) + a2);
        v128 = LODWORD(v126) + 4;
        *(_DWORD *)a3 = v128;
        v129 = *(float *)(v128 + a2);
        v128 += 4;
        *(_DWORD *)a3 = v128;
        v130 = *(float *)(v128 + a2);
        v131 = v128 + 4;
        v265 = v127;
        v268 = v129;
        v264 = v130;
        *(_DWORD *)a3 = v131;
        v293 = v129;
        v294 = 0;
        v287[0] = 0;
        Buffer[0] = 0;
        v291[0] = 0;
        v292[0] = 0;
        v290[0] = 0;
        if ( (LOBYTE(v130) & 1) != 0 )
        {
          v132 = *(_DWORD *)(v131 + a2);
          LODWORD(v264) = LODWORD(v130) & 0xFFFFFFFE;
          v133 = v131 + 4;
          *(_DWORD *)a3 = v133;
          v267 = *(void **)(v133 + a2);
          v133 += 4;
          v279 = v133;
          *(_DWORD *)a3 = v133;
          qmemcpy(Buffer, (const void *)(v133 + a2), v132);
          *(_DWORD *)a3 = v132 + v279;
          if ( v132 > 0x1E )
            COM_message("Texture name too long: %s", Buffer);
          COM_TXT_ConvertToSmallCaseString(Buffer);
          if ( COM_TXT_string_end_by(Buffer, aIfl) )
          {
            strcpy(v288, Buffer);
            sprintf(Buffer, "*%s", v288);
          }
          else
          {
            COM_TXT_CutFilenameExtension(Buffer);
          }
        }
        if ( (LOBYTE(v264) & 2) != 0 )
        {
          v134 = *(SIZE_T *)(*(_DWORD *)a3 + a2);
          v135 = v264;
          v136 = *(_DWORD *)a3 + 4;
          *(_DWORD *)a3 = v136;
          v137 = *(float *)(v136 + a2);
          dwBytes = v134;
          v269 = v137;
          v136 += 4;
          LODWORD(v264) = LODWORD(v135) & 0xFFFFFFFD;
          *(_DWORD *)a3 = v136;
          qmemcpy(v287, (const void *)(v136 + a2), v134);
          HIDWORD(v263[7]) = v287;
          *(_DWORD *)a3 = v134 + v136;
          COM_TXT_ConvertToSmallCaseString((char *)HIDWORD(v263[7]));
          if ( COM_TXT_string_end_by(v287, aIfl) )
          {
            strcpy(v288, v287);
            sprintf(v287, "*%s", v288);
          }
          else
          {
            COM_TXT_CutFilenameExtension(v287);
          }
        }
        if ( (BYTE1(v264) & 2) != 0 )
        {
          v138 = v264;
          v139 = *a3;
          dwBytes = *(SIZE_T *)(*(_DWORD *)a3 + a2);
          v140 = dwBytes;
          LODWORD(v139) += 4;
          *a3 = v139;
          v273 = *(float *)(LODWORD(v139) + a2);
          LODWORD(v139) += 4;
          LODWORD(v264) = LODWORD(v138) & 0xFFFFFDFF;
          *a3 = v139;
          qmemcpy(v290, (const void *)(LODWORD(v139) + a2), v140);
          HIDWORD(v263[7]) = v290;
          *(_DWORD *)a3 = LODWORD(v139) + v140;
          COM_TXT_ConvertToSmallCaseString((char *)HIDWORD(v263[7]));
          if ( COM_TXT_string_end_by(v290, aIfl) )
          {
            strcpy(v288, v290);
            sprintf(v290, "*%s", v288);
          }
          else
          {
            COM_TXT_CutFilenameExtension(v290);
          }
        }
        if ( (BYTE1(v264) & 4) != 0 )
        {
          v141 = *a3;
          dwBytes = *(SIZE_T *)(*(_DWORD *)a3 + a2);
          v142 = dwBytes;
          v143 = dwBytes;
          LODWORD(v141) += 8;
          LODWORD(v264) &= ~0x400u;
          *a3 = v141;
          qmemcpy(v291, (const void *)(LODWORD(v141) + a2), v143);
          HIDWORD(v263[7]) = v291;
          *(_DWORD *)a3 = LODWORD(v141) + v142;
          COM_TXT_ConvertToSmallCaseString((char *)HIDWORD(v263[7]));
          if ( COM_TXT_string_end_by(v291, aIfl) )
          {
            strcpy(v288, v291);
            sprintf(v291, "*%s", v288);
          }
          else
          {
            COM_TXT_CutFilenameExtension(v291);
          }
        }
        if ( (BYTE1(v264) & 8) != 0 )
        {
          v144 = *a3;
          dwBytes = *(SIZE_T *)(*(_DWORD *)a3 + a2);
          v145 = dwBytes;
          v146 = dwBytes;
          LODWORD(v144) += 8;
          LODWORD(v264) &= ~0x800u;
          *a3 = v144;
          qmemcpy(v292, (const void *)(LODWORD(v144) + a2), v146);
          HIDWORD(v263[7]) = v292;
          *(_DWORD *)a3 = LODWORD(v144) + v145;
          COM_TXT_ConvertToSmallCaseString((char *)HIDWORD(v263[7]));
          if ( COM_TXT_string_end_by(v292, aIfl) )
          {
            strcpy(v288, v292);
            sprintf(v292, "*%s", v288);
          }
          else
          {
            COM_TXT_CutFilenameExtension(v292);
          }
        }
        if ( v264 != 0.0 )
        {
          sprintf(v295, "BES_ID_MATERIAL: %s unsolved texture type(s): %x\n", (const char *)&v293, v264);
          if ( (LOBYTE(v264) & 4) != 0 )
            strcat(v295, aBesTexBump);
          if ( (LOBYTE(v264) & 8) != 0 )
            strcat(v295, aBesTexAmbient);
          if ( (LOBYTE(v264) & 0x10) != 0 )
            strcat(v295, aBesTexSpecular);
          if ( (LOBYTE(v264) & 0x20) != 0 )
            strcat(v295, aBesTexShinines);
          if ( (LOBYTE(v264) & 0x40) != 0 )
            strcat(v295, aBesTexGlossine);
          if ( SLOBYTE(v264) < 0 )
            strcat(v295, aBesTexSelfilum);
          if ( (BYTE1(v264) & 1) != 0 )
            strcat(v295, aBesTexOpacity);
          LG(2u, v295);
        }
        v147 = dword_101730F8;
        do
        {
          if ( (LODWORD(v264) & *v147) != 0 )
            *(_DWORD *)a3 += *(_DWORD *)(*(_DWORD *)a3 + a2) + 8;
          ++v147;
        }
        while ( v147 < dword_10173128 );
        *(float *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088) = v265;
        strcpy((char *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 8), Buffer);
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 64) = -1;
        *(float *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 92) = *(float *)&v267;
        *(float *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 100) = v269;
        *(float *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 96) = v273;
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 4) = 0;
        if ( LOBYTE(v293) == 35 )
        {
          switch ( BYTE1(v293) )
          {
            case '0':
              *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 4) = 3;
              break;
            case '1':
              *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 4) = 1;
              break;
            case '2':
              *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 4) = 4;
              break;
            case '3':
              *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 4) = 2;
              break;
            case '4':
              *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 4) = 5;
              break;
            default:
              break;
          }
        }
        if ( v287[0] )
        {
          *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 40) = HeapAlloc(
                                                                                       hHeap,
                                                                                       0,
                                                                                       strlen(v287) + 1);
          LODWORD(v273) = 15 * dword_1018F088;
          strcpy(*(char **)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 40), v287);
          *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 88) = 1120403456;
        }
        else
        {
          *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 40) = 0;
        }
        if ( v290[0] )
        {
          *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 52) = HeapAlloc(
                                                                                       hHeap,
                                                                                       0,
                                                                                       strlen(v290) + 1);
          LODWORD(v273) = 15 * dword_1018F088;
          strcpy(*(char **)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 52), v290);
        }
        else
        {
          *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 52) = 0;
        }
        if ( v291[0] )
        {
          *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 44) = HeapAlloc(
                                                                                       hHeap,
                                                                                       0,
                                                                                       strlen(v291) + 1);
          LODWORD(v273) = 15 * dword_1018F088;
          strcpy(*(char **)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 44), v291);
        }
        else
        {
          *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 44) = 0;
        }
        if ( v292[0] )
        {
          *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 48) = HeapAlloc(
                                                                                       hHeap,
                                                                                       0,
                                                                                       strlen(v292) + 1);
          LODWORD(v273) = 15 * dword_1018F088;
          strcpy(*(char **)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 48), v292);
        }
        else
        {
          *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 48) = 0;
        }
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 72) = -1;
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 68) = -1;
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 80) = -1;
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 84) = -1;
        v148 = HIWORD(v268);
        v149 = LOWORD(v268);
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 104) = LOWORD(v268);
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 108) = v149;
        *(_WORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 112) = v148;
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088++ + 56) = 0;
      }
      goto LABEL_272;
    }
    if ( v5 != (void *)4098 )
      goto LABEL_118;
    v97 = *(float *)(*(_DWORD *)a3 + a2);
    v98 = *(_DWORD *)a3 + 4;
    *(_DWORD *)a3 = v98;
    v99 = *(float *)(v98 + a2);
    v98 += 4;
    *(_DWORD *)a3 = v98;
    v98 += 4;
    v284[0] = v97;
    v100 = *(float *)(v98 + a2 - 4);
    *(_DWORD *)a3 = v98;
    v98 += 4;
    v284[1] = v99;
    v101 = *(float *)(v98 + a2 - 4);
    *(_DWORD *)a3 = v98;
    v284[2] = v100;
    LOBYTE(v100) = *(_BYTE *)(v98 + a2);
    *(_DWORD *)a3 = ++v98;
    v284[3] = v101;
    LOBYTE(v101) = *(_BYTE *)(v98 + a2);
    v98 += 3;
    *(_DWORD *)a3 = v98;
    HIDWORD(v263[7]) = *(_DWORD *)(v98 + a2);
    v102 = *((float *)&v263[7] + 1);
    LOBYTE(v284[4]) = LOBYTE(v100);
    *(_DWORD *)a3 = v98 + 4;
    BYTE1(v284[4]) = LOBYTE(v101);
    v284[5] = v102;
    v103 = HeapAlloc(hHeap, 0, HIDWORD(v263[7]));
    v104 = LODWORD(v102);
    v105 = *a3;
    LODWORD(v284[6]) = v103;
    qmemcpy(v103, (const void *)(a2 + LODWORD(v105)), v104);
    v106 = v284[1];
    v65 = (LODWORD(v284[1]) & 0x800000) == 0;
    *(_DWORD *)a3 += v104;
    if ( !v65 )
      LODWORD(v106) |= 0x40000u;
    *(float *)&v107 = 0.0;
    v284[7] = 0.0;
    if ( (LODWORD(v106) & 0x10000) != 0 )
    {
      v107 = 1;
      LODWORD(v284[7]) = 1;
    }
    if ( (LODWORD(v106) & 0x20000) != 0 )
      LODWORD(v284[7]) = ++v107;
    if ( (LODWORD(v106) & 0x40000) != 0 )
      LODWORD(v284[7]) = ++v107;
    if ( (LODWORD(v106) & 0x100000) != 0 )
      LODWORD(v284[7]) = ++v107;
    if ( (LODWORD(v106) & 0x200000) != 0 )
      LODWORD(v284[7]) = ++v107;
    if ( (LODWORD(v106) & 0x80000) != 0 )
      LODWORD(v284[7]) = ++v107;
    if ( (LODWORD(v106) & 0x400000) != 0 )
      LODWORD(v284[7]) = ++v107;
    v108 = (char *)HeapAlloc(hHeap, 0, 12 * v107);
    LODWORD(v284[8]) = v108;
    if ( *(float *)&v107 != 0.0 )
    {
      LODWORD(v264) = v108 + 8;
      v265 = *(float *)&v107;
      do
      {
        v109 = v264;
        *(_DWORD *)(LODWORD(v264) - 8) = *(_DWORD *)(*(_DWORD *)a3 + a2);
        v110 = *(_DWORD *)a3 + 4;
        *(_DWORD *)a3 = v110;
        *(_DWORD *)(LODWORD(v109) - 4) = *(_DWORD *)(v110 + a2);
        *(_DWORD *)a3 += 4;
        v111 = HeapAlloc(hHeap, 0, *(_DWORD *)(LODWORD(v109) - 4));
        *(_DWORD *)LODWORD(v109) = v111;
        qmemcpy(v111, (const void *)(a2 + *(_DWORD *)a3), *(_DWORD *)(LODWORD(v109) - 4));
        v112 = (char **)LODWORD(v264);
        *(_DWORD *)a3 += *(_DWORD *)(LODWORD(v264) - 4);
        COM_TXT_ConvertToSmallCaseString(*v112);
        if ( COM_TXT_string_end_by(*v112, aIfl) == 1 )
        {
          v113 = (char *)HeapAlloc(hHeap, 0, (SIZE_T)(*(v112 - 1) + 1));
          sprintf(v113, "*%s", *v112);
          if ( *v112 )
          {
            HeapFree(hHeap, 0, *v112);
            *v112 = 0;
          }
          *v112 = v113;
        }
        else
        {
          COM_TXT_CutFilenameExtension(*(char **)LODWORD(v264));
          v112 = (char **)LODWORD(v264);
        }
        v65 = LODWORD(v265) == 1;
        LODWORD(v264) = v112 + 3;
        --LODWORD(v265);
      }
      while ( !v65 );
      v107 = SLODWORD(v284[7]);
    }
    *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088) = LODWORD(v284[0]) | 4;
    *(float *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 104) = v284[2];
    *(float *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 108) = v284[3];
    *(_WORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 112) = LOWORD(v284[4]);
    switch ( BYTE1(v284[3]) )
    {
      case '0':
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 4) = 3;
        break;
      case '1':
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 4) = 1;
        break;
      case '2':
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 4) = 4;
        break;
      case '3':
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 4) = 2;
        break;
      case '4':
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 4) = 5;
        break;
      default:
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 4) = 0;
        break;
    }
    *(_BYTE *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 8) = 0;
    *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 40) = 0;
    *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 52) = 0;
    *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 44) = 0;
    *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 48) = 0;
    *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 56) = 0;
    *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 64) = -1;
    *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 72) = -1;
    *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 68) = -1;
    *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 80) = -1;
    *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 84) = -1;
    *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 76) = 0;
    *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 88) = 0;
    if ( *(float *)&v107 == 0.0 )
    {
LABEL_170:
      ++dword_1018F088;
      if ( LODWORD(v284[7]) )
      {
        v124 = (LPVOID *)(LODWORD(v284[8]) + 8);
        v125 = v284[7];
        do
        {
          if ( *v124 )
          {
            HeapFree(hHeap, 0, *v124);
            *v124 = 0;
          }
          v124 += 3;
          --LODWORD(v125);
        }
        while ( v125 != 0.0 );
      }
      if ( LODWORD(v284[8]) )
        HeapFree(hHeap, 0, (LPVOID)LODWORD(v284[8]));
      if ( LODWORD(v284[6]) )
        HeapFree(hHeap, 0, (LPVOID)LODWORD(v284[6]));
      v4 = a2;
      goto LABEL_272;
    }
    v114 = (const char **)(LODWORD(v284[8]) + 8);
    v265 = v284[7];
    while ( 1 )
    {
      v115 = (int)*(v114 - 2);
      if ( (v115 & 0x10000) != 0 )
      {
        strcpy((char *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 8), *v114);
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 92) = *(v114 - 2);
      }
      else if ( (v115 & 0x20000) != 0 )
      {
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 40) = HeapAlloc(
                                                                                     hHeap,
                                                                                     0,
                                                                                     (SIZE_T)*(v114 - 1));
        v116 = *v114;
        v267 = (void *)(15 * dword_1018F088);
        strcpy(*(char **)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 40), v116);
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 100) = *(v114 - 2);
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 88) = 1120403456;
      }
      else if ( (v115 & 0x840000) != 0 )
      {
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 52) = HeapAlloc(
                                                                                     hHeap,
                                                                                     0,
                                                                                     (SIZE_T)*(v114 - 1));
        v117 = *v114;
        v267 = (void *)(15 * dword_1018F088);
        strcpy(*(char **)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 52), v117);
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 96) = *(v114 - 2);
        if ( ((unsigned int)*(v114 - 2) & 0x800000) != 0 )
        {
          v118 = (int *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 96);
          v119 = *v118 | 0x40000;
LABEL_168:
          *v118 = v119;
        }
      }
      else if ( (v115 & 0x100000) != 0 )
      {
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 44) = HeapAlloc(
                                                                                     hHeap,
                                                                                     0,
                                                                                     (SIZE_T)*(v114 - 1));
        v120 = *v114;
        v267 = (void *)(15 * dword_1018F088);
        strcpy(*(char **)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 44), v120);
      }
      else if ( (v115 & 0x200000) != 0 )
      {
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 48) = HeapAlloc(
                                                                                     hHeap,
                                                                                     0,
                                                                                     (SIZE_T)*(v114 - 1));
        v121 = *v114;
        v267 = (void *)(15 * dword_1018F088);
        strcpy(*(char **)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 48), v121);
      }
      else if ( (v115 & 0x80000) != 0 )
      {
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 56) = HeapAlloc(
                                                                                     hHeap,
                                                                                     0,
                                                                                     (SIZE_T)*(v114 - 1));
        v122 = *v114;
        v267 = (void *)(15 * dword_1018F088);
        strcpy(*(char **)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 56), v122);
      }
      else if ( (v115 & 0x400000) != 0 )
      {
        *(_DWORD *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 56) = HeapAlloc(
                                                                                     hHeap,
                                                                                     0,
                                                                                     (SIZE_T)*(v114 - 1));
        v123 = *v114;
        v267 = (void *)(15 * dword_1018F088);
        strcpy(*(char **)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088 + 56), v123);
        v118 = (int *)(*(_DWORD *)(dword_1018C98C + 4) + 120 * dword_1018F088);
        v119 = *v118 | 8;
        goto LABEL_168;
      }
      v114 += 3;
      --LODWORD(v265);
      if ( v265 == 0.0 )
        goto LABEL_170;
    }
  }
  if ( v5 == (void *)81 )
  {
    v263[7] = 0LL;
    LODWORD(v265) = a1 + 128;
    v286[0] = a1 + 128;
    v96 = *a3;
    v286[1] = a1;
    v286[2] = 0;
    *(_DWORD *)(*(_DWORD *)(a1 + 132) + 64) = sub_1008F8D0(v286, LODWORD(v96) + a2 - 8, LODWORD(v96), v7, 0, 0);
    **(_DWORD **)(a1 + 132) = *(_DWORD *)LODWORD(v265);
    *(_DWORD *)a3 += v7 - 8;
    goto LABEL_272;
  }
  if ( v5 != (void *)56 )
  {
    if ( v5 == (void *)64 )
    {
      *(_DWORD *)a3 += 28;
      goto LABEL_272;
    }
    if ( v5 == (void *)80 )
    {
LABEL_56:
      dword_10240EB8 = 0;
      dword_10240EAC = 0;
      flt_10240EE0 = 0.0;
      v54 = *(float *)(*(_DWORD *)a3 + a2);
      v55 = *(_DWORD *)a3 + 4;
      *(_DWORD *)a3 = v55;
      v56 = *(_DWORD *)(v55 + a2);
      v268 = v54;
      v55 += 4;
      *(_DWORD *)a3 = v55;
      qmemcpy(&byte_1018C9BC, (const void *)(v55 + a2), v56);
      v57 = v56 + *(_DWORD *)a3;
      HIDWORD(v263[7]) = 160;
      *(_DWORD *)a3 = v57;
      v58 = (char *)HeapAlloc(hHeap, 0, HIDWORD(v263[7]));
      memset(v58, 0, 0xA0u);
      *((_DWORD *)v58 + 28) = v58;
      byte_1018C9FB = 0;
      v280 = (struct s_NOD *)v58;
      v59 = v58 + 8;
      strcpy(v59, &byte_1018C9BC);
      v60 = *v59;
      for ( i = 0; v60; v60 = v59[++i] )
      {
        if ( v60 != 32 && v60 != 9 )
          break;
      }
      v62 = v280;
      if ( *((_BYTE *)v280 + i + 8) == 62 )
        *((_DWORD *)v280 + 22) |= 0x800000u;
      v270 = 0LL;
      if ( byte_1018C9BC )
      {
        *(float *)&dwBytes = COERCE_FLOAT(&byte_1018C9BC);
        while ( 1 )
        {
          v63 = *(char *)dwBytes;
          v64 = (unsigned __int64)*(char *)dwBytes >> 32;
          v65 = *(_BYTE *)dwBytes >= 0;
          v66 = v63;
          v273 = *(float *)&v63;
          if ( v65 )
          {
            if ( v63 < 0x61 )
              goto LABEL_69;
            if ( !v64 )
              break;
          }
LABEL_73:
          v67 = *(char *)dwBytes;
          HIDWORD(v263[7]) = v64;
          COM_message("COM_HashString wrong character: %c (%d)", v67, v66);
LABEL_74:
          v263[7] = 16LL;
          v263[6] = v270 - 2;
          v68 = (HIDWORD(v270) >> 28) + 16 * (v270 - 2);
          LODWORD(v270) = LODWORD(v273) + v68;
          v69 = *(_BYTE *)(dwBytes + 1);
          HIDWORD(v270) = v64 + __CFADD__(LODWORD(v273), (_DWORD)v68) + HIDWORD(v68);
          ++dwBytes;
          if ( !v69 )
          {
            v62 = v280;
            goto LABEL_76;
          }
        }
        if ( v63 <= 0x7A )
        {
          v66 = v63 - 32;
          LODWORD(v273) = v63 - 32;
          v64 = __CFADD__(v63, -32) - 1;
        }
LABEL_69:
        if ( !v64 )
        {
          if ( v66 < 0x20 )
          {
            HIDWORD(v263[7]) = 0;
            COM_message("COM_HashString wrong character: %c (%d)", v63, v66);
          }
          if ( v66 < 0x60 )
            goto LABEL_74;
        }
        goto LABEL_73;
      }
LABEL_76:
      v70 = HIDWORD(v270);
      *((_DWORD *)v62 + 20) = v270;
      *((_DWORD *)v62 + 21) = v70;
      v71 = v268;
      v65 = LODWORD(v268) == 0;
      *((float *)v62 + 26) = v268;
      if ( v65 )
      {
        *((_DWORD *)v62 + 27) = 0;
      }
      else
      {
        v72 = 4 * LODWORD(v71);
        v73 = HeapAlloc(hHeap, 0, 4 * LODWORD(v71));
        *((_DWORD *)v62 + 27) = v73;
        memset(v73, 0, v72);
      }
      v65 = LODWORD(v272) == 80;
      *((_DWORD *)v62 + 32) = 0;
      *((_DWORD *)v62 + 33) = 0;
      *((_DWORD *)v62 + 37) = 0;
      *((_DWORD *)v62 + 34) = 0;
      *((_DWORD *)v62 + 35) = 0;
      if ( v65 )
      {
        *((_DWORD *)v62 + 31) = 4;
        *((_DWORD *)v62 + 33) = ISKE_Create();
        if ( dword_1018CEE8[0] )
          LG(0xBu, aBesLoadMultipl);
        dword_1018CEE8[0] = *((_DWORD *)v62 + 33);
      }
      else
      {
        *((_DWORD *)v62 + 31) = 6;
      }
      if ( dword_1018C970 )
      {
        v74 = (int)*(&dword_1018CEEC + 3 * dword_1018C970);
        if ( v74 + 1 <= (unsigned int)dword_1018CEE8[3 * dword_1018C970] )
        {
          *(_DWORD *)(*(_DWORD *)(dword_1018CEE4[3 * dword_1018C970] + 108) + 4 * v74) = v62;
          v75 = 12 * dword_1018C970;
          *(struct s_sphere **)((char *)&dword_1018CEEC + v75) = (struct s_sphere *)(*(char **)((char *)&dword_1018CEEC
                                                                                              + v75)
                                                                                   + 1);
          *(_DWORD *)v62 = dword_1018CEE4[v75 / 4];
          v76 = dword_1018C970;
          if ( *(&dword_1018CEEC + 3 * dword_1018C970) == (struct s_sphere *)dword_1018CEE8[3 * dword_1018C970] )
            v76 = --dword_1018C970;
          goto LABEL_91;
        }
        COM_message(aBesLoadBesRead);
      }
      else
      {
        *(_DWORD *)v62 = 0;
      }
      v76 = dword_1018C970;
LABEL_91:
      if ( v268 != 0.0 )
      {
        v77 = 3 * v76;
        dword_1018CEF0[v77] = (int)v280;
        *(float *)&dword_1018CEF4[v77] = v268;
        dword_1018CEF8[v77] = 0;
        dword_1018C970 = v76 + 1;
      }
      goto LABEL_272;
    }
LABEL_118:
    LG(2u, "Unsolved chunk: 0x%x", v5);
    *(_DWORD *)a3 += v7 - 8;
    goto LABEL_272;
  }
  v78 = *(_DWORD *)a3 + 12;
  v265 = *(float *)(*(_DWORD *)a3 + a2);
  *(_DWORD *)a3 = v78;
  if ( a1 )
  {
    v79 = *(float **)(a1 + 4);
    HIDWORD(v263[7]) = v284;
    *(float *)(a1 + 96) = v265;
    sub_100087B0((int)v79, (void *)HIDWORD(v263[7]));
    if ( v79 == (float *)-12 )
    {
      v273 = 0.0;
      v274 = 0.0;
      v275 = 0.0;
    }
    else
    {
      v80 = 1.0 / v79[18];
      v273 = v80 * v79[15];
      v274 = v80 * v79[16];
      v275 = v80 * v79[17];
    }
    v81 = *(float **)(a1 + 4);
    v265 = v265 * 0.5;
    v271 = 0.0;
    *(float *)&v270 = v265;
    HIDWORD(v270) = 0;
    sub_100087B0((int)v81, v284);
    if ( v81 == (float *)-12 )
    {
      v82 = v271;
      v277 = v270;
    }
    else
    {
      v83 = 1.0 / (*(float *)&v270 * v81[6] + v81[18]);
      *(float *)&v282 = (*(float *)&v270 * v81[3] + v81[15]) * v83;
      *((float *)&v282 + 1) = (*(float *)&v270 * v81[4] + v81[16]) * v83;
      v84 = *(float *)&v270 * v81[5] + v81[17];
      v277 = v282;
      v283 = v84 * v83;
      v82 = v283;
    }
    v278 = v82;
    v85 = *(float **)(a1 + 4);
    *((float *)&v270 + 1) = v265;
    HIDWORD(v263[7]) = v284;
    v271 = 0.0;
    LODWORD(v270) = 0;
    *(float *)(a1 + 100) = (v82 - v275) * (v82 - v275)
                         + (*((float *)&v277 + 1) - v274) * (*((float *)&v277 + 1) - v274)
                         + (*(float *)&v277 - v273) * (*(float *)&v277 - v273);
    sub_100087B0((int)v85, (void *)HIDWORD(v263[7]));
    if ( v85 == (float *)-12 )
    {
      v86 = v270;
      v87 = v271;
      v277 = v270;
    }
    else
    {
      v88 = 1.0 / (*((float *)&v270 + 1) * v85[10] + v85[18]);
      *(float *)&v282 = (*((float *)&v270 + 1) * v85[7] + v85[15]) * v88;
      *((float *)&v282 + 1) = (*((float *)&v270 + 1) * v85[8] + v85[16]) * v88;
      v89 = *((float *)&v270 + 1) * v85[9] + v85[17];
      v277 = v282;
      v283 = v89 * v88;
      v87 = v283;
      v86 = v282;
    }
    v278 = v87;
    v270 = v86;
    v271 = v87;
    v90 = (v87 - v275) * (v87 - v275)
        + (*((float *)&v277 + 1) - v274) * (*((float *)&v277 + 1) - v274)
        + (*(float *)&v277 - v273) * (*(float *)&v277 - v273);
    if ( v90 > *(float *)(a1 + 100) )
      *(float *)(a1 + 100) = v90;
    v91 = *(float **)(a1 + 4);
    v271 = v265;
    v270 = 0LL;
    sub_100087B0((int)v91, v284);
    if ( v91 == (float *)-12 )
    {
      v92 = v271;
      v277 = v270;
    }
    else
    {
      v93 = 1.0 / (v271 * v91[14] + v91[18]);
      *(float *)&v282 = (v271 * v91[11] + v91[15]) * v93;
      LODWORD(v277) = v282;
      *((float *)&v282 + 1) = (v271 * v91[12] + v91[16]) * v93;
      v94 = v271 * v91[13] + v91[17];
      HIDWORD(v277) = HIDWORD(v282);
      v283 = v94 * v93;
      v92 = v283;
    }
    v278 = v92;
    v95 = (v92 - v275) * (v92 - v275)
        + (*((float *)&v277 + 1) - v274) * (*((float *)&v277 + 1) - v274)
        + (*(float *)&v277 - v273) * (*(float *)&v277 - v273);
    if ( v95 > *(float *)(a1 + 100) )
      *(float *)(a1 + 100) = v95;
    *(float *)(a1 + 100) = sqrt(*(float *)(a1 + 100));
  }
  else
  {
    COM_message(aBesIdGobjBboxC);
  }
LABEL_272:
  while ( *(_DWORD *)a3 < LODWORD(v276) )
    sub_10008DC0(v280, v4, a3, a4);
  if ( LODWORD(v272) == 1 )
  {
LABEL_390:
    v237 = v280;
    if ( flt_10240EE0 != 0.0 )
    {
      *((float *)v280 + 23) = flt_10240EE0;
      flt_10240EE0 = 0.0;
    }
    if ( dword_10240EB0 )
    {
      HeapFree(hHeap, 0, dword_10240EB0);
      dword_10240EB0 = 0;
    }
    if ( !*((_DWORD *)v237 + 32) && COM_TXT_strings_same_len((char *)v237 + 8, aK, 2u) )
    {
      *((_DWORD *)v237 + 32) = sub_10008310(0, (int)v237, 0);
      v238 = *(_DWORD *)v237;
      *((_DWORD *)v237 + 31) = 11;
      *(_DWORD *)(v238 + 88) |= 0x2000000u;
    }
    if ( COM_TXT_strings_same_len((char *)v237 + 8, aSk, 3u) )
    {
      *((_DWORD *)v237 + 32) = sub_10008310(0, (int)v237, 2);
      v239 = *(_DWORD *)v237;
      *((_DWORD *)v237 + 31) = 12;
      *(_DWORD *)(v239 + 88) |= 0x2000000u;
    }
    if ( !*((_DWORD *)v237 + 32) && COM_TXT_strings_same_len((char *)v237 + 8, aS_0, 2u) )
    {
      *((_DWORD *)v237 + 32) = sub_10008310(0, (int)v237, 1);
      v240 = *(_DWORD *)v237;
      *((_DWORD *)v237 + 31) = 12;
      *(_DWORD *)(v240 + 88) |= 0x2000000u;
    }
    goto LABEL_402;
  }
  if ( LODWORD(v272) != 48 )
  {
    if ( LODWORD(v272) != 80 )
      goto LABEL_402;
    goto LABEL_390;
  }
  v168 = *(_DWORD ***)(a1 + 4);
  if ( v168 )
  {
    v65 = v168[24] == (_DWORD *)1;
    v168[24] = (_DWORD *)((char *)v168[24] - 1);
    if ( v65 )
    {
      if ( *v168 )
        sub_10008250(*v168, (int)(v168 + 25));
      if ( v168[2] )
      {
        HeapFree(hHeap, 0, v168[2]);
        v168[2] = 0;
      }
      if ( v168[26] )
      {
        HeapFree(hHeap, 0, v168[26]);
        v168[26] = 0;
      }
      if ( v168[23] )
      {
        HeapFree(hHeap, 0, v168[23]);
        v168[23] = 0;
      }
      HeapFree(hHeap, 0, v168);
    }
  }
  v169 = HeapAlloc(hHeap, 0, 0x6Cu);
  *(_DWORD *)(a1 + 4) = v169;
  v170 = dword_1018F090 != 0 ? 2 : 0;
  v279 = v170;
  if ( (dword_1022D620 & 1) != 0 )
  {
    v171 = dword_1018F090 != 0 ? 2 : 0;
    memset(v169, 0, 0x6Cu);
    *v169 = 0;
    v169[24] = 1;
    v169[1] = 0;
    v169[2] = 0;
    v169[26] = 0;
    v169[23] = 0;
    v169[25] = v171;
    HIDWORD(v263[7]) = 36;
    v169[26] = 0;
    v172 = HeapAlloc(hHeap, 0, HIDWORD(v263[7]));
    v169[23] = v172;
    memset(v172, 0, 0x24u);
    *(_DWORD *)(v169[23] + 32) = 1065353216;
    *(_DWORD *)(v169[23] + 28) = 1065353216;
    *(_DWORD *)(v169[23] + 24) = 1065353216;
    memset(v169 + 3, 0, 0x40u);
    v173 = v169[25];
    v169[3] = 1065353216;
    v169[8] = 1065353216;
    v169[13] = 1065353216;
    v169[18] = 1065353216;
    v169[25] = v173 | 0xC;
    v174 = *(_DWORD *)(a1 + 4);
    **(_DWORD **)(v174 + 92) = 0;
    *(_DWORD *)(*(_DWORD *)(v174 + 92) + 4) = 0;
    *(_DWORD *)(*(_DWORD *)(v174 + 92) + 8) = 0;
    *(_DWORD *)(v174 + 100) |= 4u;
    v175 = *(_DWORD *)(a1 + 4);
    *(_DWORD *)(*(_DWORD *)(v175 + 92) + 12) = 0;
    *(_DWORD *)(*(_DWORD *)(v175 + 92) + 16) = 0;
    *(_DWORD *)(*(_DWORD *)(v175 + 92) + 20) = 0;
    *(_DWORD *)(v175 + 100) |= 4u;
    v176 = *(_DWORD *)(a1 + 4);
    *(_DWORD *)(*(_DWORD *)(v176 + 92) + 24) = 1065353216;
    *(_DWORD *)(*(_DWORD *)(v176 + 92) + 28) = 1065353216;
    *(_DWORD *)(*(_DWORD *)(v176 + 92) + 32) = 1065353216;
    *(_DWORD *)(v176 + 100) |= 0xCu;
LABEL_343:
    v188 = (char *)a1;
    goto LABEL_344;
  }
  v177 = 0;
  v178 = &unk_101730E0;
  do
  {
    if ( dword_1018C974 == *v178 )
      break;
    ++v178;
    ++v177;
  }
  while ( (int)v178 < (int)dword_101730F8 );
  v179 = 0;
  v180 = &unk_101730E0;
  do
  {
    if ( *v180 == 925904944 )
      break;
    ++v180;
    ++v179;
  }
  while ( (int)v180 < (int)dword_101730F8 );
  if ( v177 >= v179 )
  {
    memset(v169, 0, 0x6Cu);
    *v169 = 0;
    v169[24] = 1;
    v169[1] = 0;
    v169[2] = 0;
    v169[26] = 0;
    v169[23] = 0;
    v169[25] = v170 | 1;
    HIDWORD(v263[7]) = 64;
    v169[23] = 0;
    v223 = HeapAlloc(hHeap, 0, HIDWORD(v263[7]));
    v169[26] = v223;
    memset(v223, 0, 0x40u);
    *(_DWORD *)(v169[26] + 60) = 1065353216;
    *(_DWORD *)(v169[26] + 40) = 1065353216;
    *(_DWORD *)(v169[26] + 20) = 1065353216;
    *(_DWORD *)v169[26] = 1065353216;
    memset(v169 + 3, 0, 0x40u);
    v169[3] = 1065353216;
    v169[8] = 1065353216;
    v169[13] = 1065353216;
    v169[18] = 1065353216;
    v169[25] |= 0xCu;
    qmemcpy(*(void **)(*(_DWORD *)(a1 + 4) + 104), &dword_10240EE4, 0x40u);
    goto LABEL_343;
  }
  v181 = v170 | 1;
  v182 = *(_DWORD *)(*(_DWORD *)a1 + 4);
  LODWORD(v270) = v170 | 1;
  if ( v182 )
  {
    if ( v169 != (_DWORD *)-100 )
    {
      v276 = *(float *)(v182 + 4);
      HIDWORD(v263[7]) = 4 * (LODWORD(v276) + 1);
      *(_DWORD *)(v182 + 4) = LODWORD(v276) + 1;
      v272 = COERCE_FLOAT(HeapAlloc(hHeap, 0, HIDWORD(v263[7])));
      v183 = *(const void **)(v182 + 8);
      if ( v183 )
      {
        qmemcpy((void *)LODWORD(v272), v183, 4 * LODWORD(v276));
        if ( *(_DWORD *)(v182 + 8) )
        {
          HeapFree(hHeap, 0, *(LPVOID *)(v182 + 8));
          *(_DWORD *)(v182 + 8) = 0;
        }
      }
      v184 = v272;
      v185 = v276;
      *(float *)(v182 + 8) = v272;
      *(_DWORD *)(LODWORD(v184) + 4 * LODWORD(v185)) = v169 + 25;
      v181 = v270;
    }
    ++*(_DWORD *)(v182 + 96);
  }
  memset(v169, 0, 0x6Cu);
  *v169 = v182;
  v169[24] = 1;
  v169[1] = 0;
  v169[2] = 0;
  v169[26] = 0;
  v169[23] = 0;
  v169[25] = v181;
  if ( (v181 & 1) != 0 )
  {
    HIDWORD(v263[7]) = 64;
    v169[23] = 0;
    v186 = HeapAlloc(hHeap, 0, HIDWORD(v263[7]));
    v169[26] = v186;
    memset(v186, 0, 0x40u);
    *(_DWORD *)(v169[26] + 60) = 1065353216;
    *(_DWORD *)(v169[26] + 40) = 1065353216;
    *(_DWORD *)(v169[26] + 20) = 1065353216;
    *(_DWORD *)v169[26] = 1065353216;
  }
  else
  {
    HIDWORD(v263[7]) = 36;
    v169[26] = 0;
    v187 = HeapAlloc(hHeap, 0, HIDWORD(v263[7]));
    v169[23] = v187;
    memset(v187, 0, 0x24u);
    *(_DWORD *)(v169[23] + 32) = 1065353216;
    *(_DWORD *)(v169[23] + 28) = 1065353216;
    *(_DWORD *)(v169[23] + 24) = 1065353216;
  }
  v188 = (char *)a1;
  memset(v169 + 3, 0, 0x40u);
  v169[3] = 1065353216;
  v189 = v169[25];
  v169[8] = 1065353216;
  v169[13] = 1065353216;
  v169[18] = 1065353216;
  v169[25] = v189 | 0xC;
  qmemcpy(*(void **)(*(_DWORD *)(a1 + 4) + 104), &dword_10240EE4, 0x40u);
  v190 = *(_DWORD *)(a1 + 4);
  v191 = *(_DWORD *)(v190 + 100);
  if ( (v191 & 2) == 0 && ((v191 & 4) != 0 || *(_DWORD *)v190 && sub_10008790(*(int ***)v190)) )
  {
    for ( j = 0; j < *(_DWORD *)(v190 + 4); ++j )
    {
      v193 = *(_DWORD **)(*(_DWORD *)(v190 + 8) + 4 * j);
      *v193 |= 4u;
    }
    v65 = *(_DWORD *)v190 == 0;
    v194 = *(float **)(v190 + 92);
    *(_DWORD *)(v190 + 100) &= ~4u;
    if ( !v65 )
    {
      if ( v194 )
      {
        v195 = v194[8];
        v284[3] = 0.0;
        v196 = v194[7];
        v284[7] = 0.0;
        v197 = v194[6];
        v198 = v194[5];
        v199 = v194[4];
        v200 = v194[3];
        *(float *)&dwBytes = cos(v200);
        v265 = cos(v199);
        v268 = cos(v198);
        v264 = sin(v200);
        *(float *)&v267 = sin(v199);
        v269 = sin(v198);
        v284[0] = v268 * v265 * v197;
        v284[1] = -(v269 * v265 * v197);
        v284[2] = *(float *)&v267 * v197;
        v284[4] = (*(float *)&v267 * v264 * v268 + v269 * *(float *)&dwBytes) * v196;
        v272 = v269 * *(float *)&v267;
        v284[5] = v268 * *(float *)&dwBytes * v196 - v264 * v196 * v272;
        v284[6] = -(v264 * v265 * v196);
        v284[8] = v269 * v264 * v195 - *(float *)&v267 * v268 * *(float *)&dwBytes * v195;
        v284[9] = (v264 * v268 + *(float *)&dwBytes * v272) * v195;
        v284[10] = v265 * *(float *)&dwBytes * v195;
        v284[12] = *v194;
        v201 = v194[1];
        v284[11] = 0.0;
        v284[13] = v201;
        v202 = v194[2];
        v284[15] = 1.0;
        v284[14] = v202;
        qmemcpy(v263, v284, sizeof(v263));
        sub_100087B0(*(_DWORD *)v190, &v247);
        v203 = sub_10005920(
                 v284,
                 v247,
                 v248,
                 v249,
                 v250,
                 v251,
                 v252,
                 v253,
                 v254,
                 v255,
                 v256,
                 v257,
                 v258,
                 v259,
                 v260,
                 v261,
                 v262,
                 v263[0]);
      }
      else
      {
        qmemcpy(v263, *(const void **)(v190 + 104), sizeof(v263));
        sub_100087B0(*(_DWORD *)v190, &v247);
        v203 = sub_10005920(
                 v298,
                 v247,
                 v248,
                 v249,
                 v250,
                 v251,
                 v252,
                 v253,
                 v254,
                 v255,
                 v256,
                 v257,
                 v258,
                 v259,
                 v260,
                 v261,
                 v262,
                 v263[0]);
      }
      v204 = (void *)(v190 + 12);
      v205 = v203;
      goto LABEL_322;
    }
    if ( !v194 )
    {
      v205 = *(const void **)(v190 + 104);
      v204 = (void *)(v190 + 12);
LABEL_322:
      qmemcpy(v204, v205, 0x40u);
      goto LABEL_323;
    }
    v206 = v194[2];
    v207 = v194[1];
    v276 = v194[4];
    v208 = *v194;
    v209 = v194[8];
    v210 = v194[7];
    v211 = v194[6];
    v212 = v194[5];
    v213 = v194[3];
    v272 = v213;
    *(_DWORD *)(v190 + 24) = 0;
    *(_DWORD *)(v190 + 40) = 0;
    v264 = cos(v213);
    v269 = cos(v276);
    v268 = cos(v212);
    *(float *)&dwBytes = sin(v272);
    *(float *)&v267 = sin(v276);
    v265 = sin(v212);
    *(float *)(v190 + 12) = v268 * v269 * v211;
    *(float *)(v190 + 16) = -(v265 * v269 * v211);
    *(float *)(v190 + 20) = *(float *)&v267 * v211;
    *(float *)(v190 + 28) = (*(float *)&v267 * *(float *)&dwBytes * v268 + v265 * v264) * v210;
    v272 = v265 * *(float *)&v267;
    *(float *)(v190 + 32) = v268 * v264 * v210 - *(float *)&dwBytes * v210 * v272;
    *(float *)(v190 + 36) = -(*(float *)&dwBytes * v269 * v210);
    *(float *)(v190 + 44) = v265 * *(float *)&dwBytes * v209 - *(float *)&v267 * v268 * v264 * v209;
    v214 = *(float *)&dwBytes * v268 + v264 * v272;
    *(_DWORD *)(v190 + 56) = 0;
    *(_DWORD *)(v190 + 72) = 1065353216;
    *(float *)(v190 + 48) = v214 * v209;
    *(float *)(v190 + 52) = v269 * v264 * v209;
    *(float *)(v190 + 60) = v208;
    *(float *)(v190 + 64) = v207;
    *(float *)(v190 + 68) = v206;
  }
LABEL_323:
  v215 = (const void *)(v190 + 12);
  v216 = *(void ***)(a1 + 4);
  qmemcpy(v284, v215, sizeof(v284));
  v217 = (_DWORD **)*v216;
  if ( *v216 )
  {
    if ( v216 != (void **)-100 )
    {
      v218 = v217[1];
      v219 = 0;
      if ( v218 )
      {
        v220 = (void ***)v217[2];
        do
        {
          if ( *v220 == v216 + 25 )
            break;
          ++v219;
          ++v220;
        }
        while ( v219 < (unsigned int)v218 );
      }
      v221 = v217[2];
      v222 = (int)v218 - 1;
      v217[1] = (_DWORD *)v222;
      v221[v219] = v221[v222];
    }
    v65 = v217[24] == (_DWORD *)1;
    v217[24] = (_DWORD *)((char *)v217[24] - 1);
    if ( v65 )
    {
      if ( *v217 )
        sub_10008250(*v217, (int)(v217 + 25));
      if ( v217[2] )
      {
        HeapFree(hHeap, 0, v217[2]);
        v217[2] = 0;
      }
      if ( v217[26] )
      {
        HeapFree(hHeap, 0, v217[26]);
        v217[26] = 0;
      }
      if ( v217[23] )
      {
        HeapFree(hHeap, 0, v217[23]);
        v217[23] = 0;
      }
      if ( v217 )
        HeapFree(hHeap, 0, v217);
    }
  }
  *v216 = 0;
  qmemcpy(*(void **)(*(_DWORD *)(a1 + 4) + 104), v284, 0x40u);
LABEL_344:
  if ( byte_1018C9BC == 36 )
  {
    sub_100181C0(v188, *(_DWORD *)v188, &dword_10240EA8);
  }
  else if ( COM_TXT_strings_same_len(v188 + 8, aK, 2u) )
  {
    v263[7] = 0LL;
    HIDWORD(v263[6]) = &dword_10240EA8;
    *((_DWORD *)v188 + 31) = 11;
    *((_DWORD *)v188 + 32) = sub_10008310((unsigned int *)HIDWORD(v263[6]), v263[7], SHIDWORD(v263[7]));
    *(_DWORD *)(*(_DWORD *)v188 + 88) |= 0x2000000u;
  }
  else
  {
    if ( !COM_TXT_strings_same_len(v188 + 8, aS_0, 2u) )
    {
      if ( byte_1018C9BC == 42 )
        *((_DWORD *)v188 + 22) |= 0x80u;
      if ( byte_1018C9BC == 33 )
      {
        v224 = sub_10034D10(&dword_10240EA8);
        HIDWORD(v263[7]) = &dword_10240EA8;
        *((_DWORD *)v188 + 32) = v224;
        *((_DWORD *)v188 + 31) = 3;
        sub_10005AC0(v188, (_DWORD *)HIDWORD(v263[7]));
      }
      else
      {
        v279 = 0;
        v225 = sub_10006C50(dword_10240EB0, (int)v284);
        HIDWORD(v263[7]) = &dword_10240EA8;
        if ( v225 )
        {
          sub_100185A0(v188, v284, HIDWORD(v263[7]));
          goto LABEL_379;
        }
        sub_10005AC0(v188, (_DWORD *)HIDWORD(v263[7]));
        *((_DWORD *)v188 + 32) = sub_10007950((struct I3D_CreateObjectProp *)&dword_10240EA8, (char *)&v279, (int)v188);
        v226 = v279;
        if ( (v279 & 0x8000) != 0 )
          *((_DWORD *)v188 + 22) |= 0x4000u;
        if ( (v226 & 0x10000) != 0 )
          *((_DWORD *)v188 + 22) |= 0x20000u;
        *((_DWORD *)v188 + 31) = 1;
        v227 = 0;
        if ( dword_10240EA8 )
        {
          v228 = (int *)dword_10240EB4;
          while ( 1 )
          {
            v229 = *v228;
            if ( *v228 )
            {
              if ( (*(_BYTE *)v229 & 4) != 0
                && __PAIR16__(BYTE1(*(_DWORD *)(v229 + 104)), *(_BYTE *)(v229 + 104)) != 8237 )
              {
                break;
              }
            }
            ++v227;
            v228 += 7;
            if ( v227 >= dword_10240EA8 )
              goto LABEL_369;
          }
          if ( v227 < dword_10240EA8 )
            *((_DWORD *)v188 + 22) |= 0x6000000u;
        }
      }
LABEL_369:
      if ( dword_1018F090 )
      {
        v230 = sub_1006C580((char)&byte_1018C9BC, (int)&v285);
        v231 = (_DWORD *)*((_DWORD *)v188 + 32);
        LOBYTE(v270) = v230;
        if ( v230 == 15 )
        {
          if ( v231[7] )
          {
            v232 = (*(int (__thiscall **)(_DWORD *, _DWORD, _DWORD))(*v231 + 28))(v231, 0, 0);
            v233 = 0.0;
            if ( v232 )
            {
              do
              {
                v234 = *v231;
                v284[0] = v233;
                (*(void (__thiscall **)(_DWORD *, float *))(v234 + 32))(v231, v284);
                ++LODWORD(v233);
                *(_DWORD *)LODWORD(v284[5]) |= 2u;
              }
              while ( LODWORD(v233) < v232 );
            }
          }
          else
          {
            COM_message("Object with no vertices: %s", &byte_1018C9BC);
          }
        }
        else
        {
          if ( !*(_DWORD *)(dword_1018CEE8[0] + 68) )
            *(_DWORD *)(dword_1018CEE8[0] + 68) = sub_1006A080();
          sub_1006ACA0(v231, &byte_1018C9BC, v270, v285);
        }
      }
      goto LABEL_379;
    }
    v263[7] = 0x100000000LL;
    HIDWORD(v263[6]) = &dword_10240EA8;
    *((_DWORD *)v188 + 31) = 12;
    *((_DWORD *)v188 + 32) = sub_10008310((unsigned int *)HIDWORD(v263[6]), v263[7], SHIDWORD(v263[7]));
    *(_DWORD *)(*(_DWORD *)v188 + 88) |= 0x2000000u;
  }
LABEL_379:
  v235 = 0;
  if ( dword_10240EA8 )
  {
    v236 = 0;
    do
    {
      if ( *(_DWORD *)((char *)dword_10240EB4 + v236 + 24) )
      {
        HeapFree(hHeap, 0, *(LPVOID *)((char *)dword_10240EB4 + v236 + 24));
        *(_DWORD *)((char *)dword_10240EB4 + v236 + 24) = 0;
      }
      if ( *(_DWORD *)((char *)dword_10240EB4 + v236 + 20) )
      {
        HeapFree(hHeap, 0, *(LPVOID *)((char *)dword_10240EB4 + v236 + 20));
        *(_DWORD *)((char *)dword_10240EB4 + v236 + 20) = 0;
      }
      ++v235;
      v236 += 28;
    }
    while ( v235 < dword_10240EA8 );
  }
  if ( dword_10240EB4 )
  {
    HeapFree(hHeap, 0, dword_10240EB4);
    dword_10240EB4 = 0;
  }
  if ( dword_10240EB0 )
  {
    HeapFree(hHeap, 0, dword_10240EB0);
    dword_10240EB0 = 0;
  }
LABEL_402:
  v241 = v280;
  if ( v280 )
  {
    if ( (*((_DWORD *)v280 + 22) & 0x4000) != 0 )
    {
      v242 = dword_1018C994;
      v243 = dword_1018C990;
      v244 = HeapAlloc(hHeap, 0, 0x84u);
      *((_DWORD *)v241 + 33) = sub_10017800(v241, v243, v242) != 0 ? v244 : 0;
    }
    if ( (*((_DWORD *)v241 + 22) & 0x20000) != 0 )
    {
      v245 = HeapAlloc(hHeap, 0, 0xC8u);
      *((_DWORD *)v241 + 33) = sub_10016DF0(v241) != 0 ? v245 : 0;
    }
  }
  return v241;
}