//**************************************************
//          C:\ALASKA\Best\BADI\BClasses\Tax\clsTax_Inv.prg
//**************************************************
//    Счет-фактура (шапка)

#include "hbclass.ch"
#include "..\include\BO_Const.ch"
#include "table_always_open.ch"

#define _SFID     1
#define _SFSTRID  2
#define _DOCID    3
#define _DOCSTRID 4
#define _JRNID    5
#define _DEL      6
#define _STATUS   7
#define _KEY      8
#define _DOCRECNO 9

#define _TAXID     1
#define _CALCRL    2
#define _MODBS     3
#define _STRID     4
#define _RTDEF     5
#define _RTRATE    6
#define _SYSNUM    7
#define _PRIOR_    8
#define _OUTF      9
#define _INF       10
#define _TAXCODE_  11
#define _PRICEIN   12
#define _SUMUSE    13
// Масси первоначальных настроек
#define _TAX_SM_PS      1 //-объединять одноименные позиции
#define _TAX_CNT        2 //- соблюдать хронологию,
#define _TAX_RET        3 //- обычная или отрицательная С_Ф при возвратах
#define _TAX_MOD        4 //- ID налоговой модели
#define _TAX_ENT_ID     5 //- собственное предприятие
#define _TAX_ENT_ADDRID 6 //- собственное как грузополучатель
#define _TAX_OUT_PL     7 //учетная политика
#define _TAX_DOCTYPE    8 //- тип документа
#define _TAX_SFCUR      9 //- можно или нет создавать валютные с-ф
#define _TAX_DATE_BEG   10 //- дата начала работы подсистемы
#define _TAX_TAX_PERIOD 11 //- налоговый период (0-месяц, 1-квартал)
#define _TAX_QUE        12 //- запись в книгу по запросу 1
#define _TAX_BANK_AV    13 //- создание авансового с-ф из банка 0 - не создавать 1 по запросу 2 автоматически
#define _TAX_CASH_AV    14 //- создание авансового с-ф из кассы 0 - не создавать 1 по запросу 2 автоматически
#define _TAX_DOPSF      15 //- T примечание из документа источника
#define _TAX_COMCF      16 //- T комментарий из документа источника
#define _TAX_IN_NUM     17 //- T проверяем уникальность на закупках по партнеру
#define _TAX_NM_AV      18 // T - из документа  Наименование авансового счета-фактуры
#define _TAX_NM_AV_TXT  19 // Текст наименования
#define _TAX_DOP_AV     20 // T - из документа  Дополнение авансового счета-фактуры
#define _TAX_COM_AV     21 // Т - из документа Комментарий авансового счета-фактуры
#define _TAX_ENT_SEL    22 // T - можно изменить собственное предприятие
#define _TAX_USE_DOPNUM 23 // T - использовать доп номер
#define _TAX_INI_DOPNUM 24 // инициировать доп номер значкением
#define _TAX_DNUM_RUL   25 // Т  доп номер грузоотправитель

#define _ALLOWED_ 1
#define _VIEW_    2
#define _NEW_     3
#define _EDIT_    4
#define _DELETE_  5
#define _PRINT_   6
#define _DESIGN_  7
***************************************************
* public funcs
***************************************************
* возвращает массив параметров , {lPay, cClassName}
function taxGetParamsForStr( StrTp ,MoveTp)
  local lPay := .F., cClsName := ""
  // для аванса тип строк может быть отличный от 0 1
  if  MoveTp $ "ПР,ПП"
    RETURN { .T., "" }
  endif
  do case
    case StrTp == "0"
      lPay := .T.
    case StrTp == "1"
      lPay := .T.
    case StrTp == "2"
      cClsName := "clsTaxSclad_Mgrup"
    case StrTp == "3"
      cClsName := "clsTaxZapas_Mgrup"
    case StrTp == "4"
      cClsName := "clsTaxTovar_Mgrup"
    case StrTp == "5"
      cClsName := "clsTaxAssets_Mgrup"
    case StrTp == "6"
    otherwise
     return {nil,nil}
  endcase

RETURN { lPay, cClsName }

***************************************************

CLASS clsTax_Inv FROM clsMetaBO
  PROTECTED:
    var  mModId
    var  mTI_CTG
    var  mMove_Tp
    //var  mStr_Tp
    var  mPkDoc   //значение ключа дос-та из которого создаем счет-фактуру
    var  mDocType
    var  mDocDate
    var  mEntId
    var  mEntADDRId
    var  mVAL_ID init ""//идентификатор основной валюты
    var  mMainCurCode init ""


    var aTabCnt // массив - 1 тип сделки
                // 2 - рекорд на таблицу документов основания

    var ObjMOVE_TP init ""
    var ObjDOC_TYPE init ""
    var STPTP init ""
    var mTbPartAddr //рекордсет на таблицу адресов партнера
    var mTbSeg init ""// роекордсет аналитических сегментов под счет
    var mTbCard //рекордсет карточек
    var mTbApReg
    var mAnlSeg init ""
    var mCardId //  карточка
    var mCardPartner // партнер карточки расчетов
    var mCardRecNo
    var maTran init {}
    var mEditValue init {}
    Var NewFieldList init ""

  EXPORTED:
    var IsGenDocNum init .F.
    var mTbPeople
    var aRight init {}
    var mDateSf
    var mlEditStr init .F.
    var mDelBook init .F. // Флаг - нужно удалить записи не сохраняя с-ф - изменились параметры для регистрации
    var mDelRecBook init .F. // Флаг - нужно удалить записи не сохраняя с-ф - изменились параметры для регистрации
    var mTbInv init ""  // рабочая область счет-фактуры
    var mTbInvArc init ""  // рабочая область счет-фактуры архивной - для работы с корректиро. или исправ. в архивном периоде.
    var mCreateFromArc init .F.
    var aStrS init {}
    var mlKorr init .F.
    var mlIspr init .F.
    var mOldKorr init ""
    var mnSort init -1
    var mArc init .F.
    var mlSaveOnly init .F.  //Флаг обязательного сохранения - после правки окументов
    // нужно обязательно сохранить с-ф
    var mAliasInv init ""
    var mAliasSum init "" // алиас сумм
    var mAliasStr init "" // алиас строк
    var mAliasSin init "" // алиас для синхронизации строк в архивном и текущем
    var mAliasTaxTp init ""
    var mParamIni init {}//массив параметров настройки системы
    var mMultyStorno
    var mGroupSf // создается групповой С-ф
    Var oSelf
    Var aMsqNotSave
    Var lMsgErrShow init .T.
    Var lMsgDelBook init .T.
    var mlRegDoc // T - есть зарегистрированные документы
    // {журнал, рекорд на таблицу, recno документов используемых в с-ф }
    var aTab //массив 1 - таблица из которой д-ты,
                // 2 - индекс для ключа документа
                 // 3 индекс для идентификатора С_Ф
    var maTbDoc Init {} // массив таблиц связанных д-тов
    Var maJrnDocDim Init {}
    Var mRound init 2
    Var mlYesDoc init .F.// Т - есть документы при взятии на редактирование
    var aSFDOC init {}
    Var mlCreateRec init .T.
    Var mlFromDoc init .F. //T - с-ф создали из документа - при сохранении - выдаем запрос на возврат в документ
    Var mnRecAddDoc init 0
    Var mcJrnAddDoc init ""
    Var mNoAddArrEdit init .F.
    Var mReMakeBook init .F. // Проверять соответствие записи сумме по документу
    Var maReRegDoc init {} // массив параметров документа который изменяли
    Var mlMsgForReg init .T. // задавать или нет запрос на сохранение
    Var mlHandSum init .F.  // если дата меньше начала даты периода - и нет суммы записи стартовать
                           //или нет форму ручного ввода суммы

    Var mlReg init .T. // В зависимости от того при пересоздании
    // с-ф для первой с-ф произвели регистрацию в книгу Т илинет
    //Var cGenPAddSclad init "0" //как заполнять партию для Sclad
    //Var cGenPAddZapas init "0" //как заполнять партию для Zapas
    Var mlRePlaceMod init .F.  // При замене налоговой модели сохраняем если изменились параметрыс-ф
    Var mlReCreateBook init .F.// если изменились параметры с-ф нужно пересоздать записи в книгу

    ACCESS ASSIGN METHOD DOC_ID()    // c 22 N(10,0)  Уникальный идентификатор документа в журнале
    ACCESS ASSIGN METHOD TI_CTG()    // C(01)    Категория счета-фактуры
    ACCESS ASSIGN METHOD MOVE_TP()   // C(02)    Вид движения счета-фактуры
          ACCESS  METHOD MOVE_NAME()
    //ACCESS ASSIGN METHOD STR_TP()    // C(01)    Тип строк
    ACCESS ASSIGN METHOD DOC_TP()    //c 22 N(10,0)  Вид документа
           ACCESS METHOD CODE_TP()
    ACCESS ASSIGN METHOD DOC_NUM()   // C - 24  C (15) - C(06)    Номер документа
    ACCESS ASSIGN METHOD DOC_DATE()  // D        Дата документа
    ACCESS ASSIGN METHOD REG_NUM()   // C(06)    Номер документа
    ACCESS ASSIGN METHOD REG_DATE()  // D        Дата регистрации
    ACCESS ASSIGN METHOD ENT_ID()  // c 22 N10(06)    Код собственного предприятия
    ACCESS ASSIGN METHOD ENT_ADDRID() // c 22
    ACCESS ASSIGN METHOD PRT_ID()  // c 22 N10(06)    Код партнера
    ACCESS ASSIGN METHOD PRT_ADDRID() //c 22
    ACCESS ASSIGN METHOD VAL_ID()  // c 22 C(03)    Код валюты
    ACCESS ASSIGN METHOD VAL_RATE()  // N(19,5)  Курс на дату регистрации?
    ACCESS ASSIGN METHOD SUM_NNDS()  // N(19,4)  Сумма в валюте без НДС
    ACCESS ASSIGN METHOD SUM_NDS()   // N(19,4)  Сумма НДС в валюте
    ACCESS ASSIGN METHOD SUM_A()     // N(19,4)  Сумма в валюте с НДС
    ACCESS ASSIGN METHOD SUM_BOOK()  // N(19,4)  Сумма по книге в валюте?
    ACCESS ASSIGN METHOD SUM_PAY()  // N(19,4)  Сумма оплаты в валюте
    ACCESS ASSIGN METHOD SUM_SHP()  // N(19,4)   Сумма оприходования- отгрузки в валюте
    ACCESS ASSIGN METHOD ST_SUM()  // N(19,4)    Сумма сторно
    ACCESS ASSIGN METHOD COMMENT_m() // M        Комментарий
    ACCESS ASSIGN METHOD COMPL_m()   // M        Дополнение
    ACCESS ASSIGN METHOD ACNT_ID()      //c 16 На ключ - N10 C(16)    Счет
    ACCESS ASSIGN METHOD ANALIT()    // C(24)    Аналитика
    ACCESS ASSIGN METHOD ENT_LOC() //c 22 - идентификатор адреса грузополучателя собственного предприятия
    ACCESS ASSIGN METHOD PRT_LOC() //c 22 - идентификатор адреса грузополучателя партнера
    ACCESS ASSIGN METHOD CNT_TYPE() //c 1 тип сделки основания
    ACCESS ASSIGN METHOD CNT_DOC_ID() //c 22 идентификатор сделки
    ACCESS ASSIGN METHOD IS_FULL()   //L T полностью разнесенная с-ф
    ACCESS ASSIGN METHOD PRT_TP()   // c 1 тип партнера 1 - партнер 2 сотрудник

    ACCESS ASSIGN METHOD STR_TP2 //L(1)
    ACCESS ASSIGN METHOD SHP_TP2 //L(1)
    ACCESS ASSIGN METHOD STR_TP3 //L(1)
    ACCESS ASSIGN METHOD SHP_TP3 //L(1)
    ACCESS ASSIGN METHOD STR_TP4 //L(1)
    ACCESS ASSIGN METHOD SHP_TP4 //L(1)
    ACCESS ASSIGN METHOD STR_TP5 //L(1)
    ACCESS ASSIGN METHOD SHP_TP5 //L(1)
    ACCESS ASSIGN METHOD MOD_ID  //C(22)
    ACCESS ASSIGN METHOD ID_OBL  //C(22)
    ACCESS ASSIGN METHOD IS_ANUL //L 1
    ACCESS ASSIGN METHOD DOCDIM // C(60)
    ACCESS ASSIGN METHOD PAY_COMM //(M) Расчетно-платежный документ - текстом
    ACCESS ASSIGN METHOD AnalitName

    ACCESS ASSIGN METHOD KOP_NDS  //C(2)
    ACCESS ASSIGN METHOD KOP_AST  //C(7)
    ACCESS ASSIGN METHOD KOP_NNDS  //C(7)
    ACCESS ASSIGN METHOD KOP_NDS0  //C(7)
    ACCESS ASSIGN METHOD KOP_AG_NDS  //C(7)

    ACCESS ASSIGN METHOD PODRAZD  //C(6)
    ACCESS ASSIGN METHOD KORR //L
    ACCESS ASSIGN METHOD SFK_ID //C(22)
    ACCESS ASSIGN METHOD DEF //L
    ACCESS ASSIGN METHOD SFD_ID //C(22)
    ACCESS ASSIGN METHOD FROM_ARC //L
    ACCESS ASSIGN METHOD DNUM //c(10) - 40
    ACCESS ASSIGN METHOD MET_FORM
    ACCESS ASSIGN METHOD SFMD_ID
    ACCESS ASSIGN METHOD MD_ID
    ACCESS ASSIGN METHOD IS_COMB //L
    ACCESS ASSIGN METHOD SF_BRG

    ACCESS METHOD KOPNDSNAME  //C(50)
    ACCESS METHOD KOPASTNAME
    ACCESS METHOD KOPNNDSNAME  //C(50)
    ACCESS METHOD KOPNDS0NAME  //C(50)
    ACCESS METHOD KOPAGNDSNAME  //C(50)

    ACCESS METHOD ENT_NAME()
    ACCESS METHOD ENT_CODE()
    ACCESS METHOD ENT_ADDRNAME()
    ACCESS ASSIGN METHOD ENT_ADDRCODE()
    ACCESS METHOD ENT_LOCNAME()
    ACCESS METHOD PARTNER_NAME()
    ACCESS ASSIGN METHOD PARTNER_CODE()
    ACCESS METHOD PARTNER_ADDRNAME()
    ACCESS METHOD PARTNER_LOCNAME()
    ACCESS ASSIGN METHOD PARTNER_ADDRCODE()
    ACCESS METHOD VALCODE()
    ACCESS METHOD VALMAIN()
    //ACCESS METHOD STRTPNAME()
    ACCESS METHOD ACNTNAME()
    ACCESS METHOD CNTVID()
    ACCESS METHOD CNTNUM()
    ACCESS METHOD CNTDATE()
    ACCESS METHOD CNTDOCDIM()
    ACCESS METHOD SFANALIT()
    ACCESS METHOD CNTANALIT()
    ACCESS METHOD STSUM() //Не отсторнированная сумма
    ACCESS METHOD OBLNUM()
    ACCESS METHOD SFKVID()  // Вид корректируемого с-ф
    ACCESS METHOD SFKNUM()  // Номер корректируемого с-ф
    ACCESS METHOD SFKDATE() // Дата корректируемого с-ф
    ACCESS METHOD SFKDOPNUM() //Доп номер связанного с-ф

    METHOD Init()
    METHOD BeforeAppend(TI_CTG, Move_Tp,sPkDoc )
    METHOD Append()
    METHOD edit()
    Method Save()
    Method Delete()
    Method Destroy()

    Method GetAnalit()      //получаем по партнеру значение аналитики
    Method IsValMain(lRet)
    Method CreateStrForDoc() // создание строк из документов
    Method ClearMarkForStrDocm() // снятие в строкач документа отметки
    Method CreateForDoc51Order(oObjDoc,nFor)
    Method CreateForDoc51OrderRBook(oObjDoc,nFor)
    Method CheckRBook()
    Method IsRBook()
    Method CheckTaxForZac()
    Method CreateForFinDoc()
    Method CreateForScladZapasTovarReal(Obj,lVMain,nFor) //,lTovar)
    Method CreateForAssets()
    Method CreateArrStrAssets()
    Method CreateTaxForSF()
    Method GetDocRecNo(aRecNo)
    Method ClearMarkStrInDoc() // удаляем ссылку на строку при удалении строки
    Method SetStrDoc() // получить таблицы строк документов
    Method CreateAVForBook()//создание записи в книгу для Авансового С-Ф
    Method CreateRecInBook()
    Method CreateStorno()
    Method CreateStornoRecInBook()
    Method CreateArrayFromStr()
    //Method CreateArrayFromStr1()
    Method CreateGroupRecInBook()
    Method CreateKorrRecInBook()
    Method CreateRecForGroupInBook()
    Method CreateRecInBookWithoutDoc()
    //Method GetPartnerCodeName(nIdPartner,lCode)
    Method GetPartnerEval(nIdPartner,cExp,cValue)
    Method CreateDocument()
    Method GetPSchName(cSchet)
    Method GetSfFieldName(cStrTp)
    Method GetNextNumInv()//перенумерация д-та при смене типа или года
    Method CardYes() // Есть ли карточка под С/ф
    Method CheckCard() //Синхронизация или создание новой карточки
    Method CheckUniqueNum() //Проверка номера на уникальность
    Method OldCard()
    Method CreateCard()
    Method DeleteCard()
    Method RegDocForSF()
    Method ReLockDocForSf()
    Method RecoverAnulRecords() //востановление аннулированных записей
    Method GetAddrName(lEnt) //Получение адреса по идентификатору
    Method CreateBrg(cCnt) //создание рекордов на документы основания
    Method GetBrg(nParam) // поллучение параметра документа основания
    Method CheckObl() //Проверка наличия обязательного этапа
    Method lTaxNds(cTaxId)
    Method ChengeSumStatus()
    METHOD Open()
    Method SetParamStrSum()
    Method Pereschet()
    Method GetDocForStr()
    Method ReplaceNdsFromKalk() //Замена значений в строке налогов для НДС согласно калькуляции
    //Method GetPAdd()
    method DelAllStr()
    Method LenNum()
    Method lNegativPozit()
    Method DelAllRec()
    Method GetTaxInvFrom()
    //Method AsKorr()
    ACCESS METHOD SelectKorrSf
    Method SeekFromArc

    ACCESS METHOD TAX_STR()  //
    ACCESS METHOD BOOK
    ACCESS METHOD BOOKST
    //ACCESS METHOD PRM

    ACCESS METHOD FieldList()

    ACCESS METHOD CheckBeforeEdit
    ACCESS METHOD CheckBeforeSave   //метод проверки возможности записи
    ACCESS METHOD CheckBeforeDel    //метод проверки возможности удаления
    ACCESS METHOD CheckBeforeAdd    //метод проверки возможности создания

ENDCLASS

//-----------------------------

METHOD clsTax_Inv:Init(xParam)
//altd()
  if ValType(xParam) == "C"
    if !Upper(Alltrim(xParam)) == Upper('ree')
      ::NewFieldList := xParam
    endif
  endif
  ::clsMetaBO:Init()
  ::MBOVERSION := 1
  // pg - 16_09_09 38051,38052
  // пишем в изменение рег номер - юридический в комментарий
  //[Forward note from Александр Титов -- 07.09.09 16:04:54]
  // В комментариях (там где партнер) надо вписать еще юр.номер
  ::aJrnCodeDoc := {"DOC_ID",;                     // 1-имя поля первичного ключа
                    "Счета-фактуры",;              // 2-наименование реестра (16 символов) - типа jrn_name в jrn_sys.dbf
                    "С/Ф",;                        // 3-сокращенное наименование реестра (9 символов) - типа brg_name
                    {||Field->CODE_TP},;                // 4-блок кода, возвращающий вид документа (стоим в документе)
                    {||Field->REG_NUM/*Doc_Num*/},;                // 5-блок кода для номера документа
                    {||Field->REG_DATE/*Doc_date*/},;               // 6-блок кода для даты документа
                    {|pr,cNum|pr:=Field->prt_id, cNum := if((DIC_PARTNER)->(DBSEEK(pr)),(DIC_PARTNER)->shortname,""), cNum + " Юр.ном." + Field->Doc_Num + " от " + DTOC(Field->Doc_date) },;// 7-блок кода для наименования партнера
                    {||Field->Sum_A},;                  // 8-блок кода для суммы
                    {||if(Field->ti_ctg=="1","+","-")},;// 9-блок кода для признака прихода-расхода, должен возвратить "+" или "-" или пробел
                    "1601";                        //10-код журнала (4 символа) должен быть уникальным для реестра
                   }
//altd()
  ::NameBO      := "clsTax_Inv"
  ::ModifyType  := mtNewEditDel
  ::clsMetaBO:subself:=self
  ::FnCheckBeforeEdit:="CheckBeforeEdit"
  ::FnCheckBeforeSave:="CheckBeforeSave"//имя функции,вызываемую для проверки возможности сохранения
  ::FnCheckBeforeDel :="CheckBeforeDel"//имя функции,вызываемую для проверки возможности удалить
  ::FnCheckBeforeAdd :="CheckBeforeAdd"//имя функции,вызываемую для проверки возможности создать новую
  ::PrimaryKey := {"DOC_ID","TAG_ID","SEQ01",.T.}//описание первичного ключа{<Имя поля>,<Имя индекса>,<правило нумерации>}{"ID_OP","ID_OP","CASH"}
                //Prm;
  ::CHILDLIST := "TAX_STR;TAX_STR:TAXSTRSUM;BOOK;BOOKST"

   ::SortList  := "TAG_MOVE;виду движения;"+;
                  "TAG_DTNUM;дате,номеру;"+;
                  "TAG_NUMDT;номеру, дате;"+;
                  "TAG_DTNUMR;дате регистрации,регистрационному номеру;"+;
                  "TAG_NUMDTR;регистрационному номеру, дате регистрации;"+;
                  "PART_TEMP{TI_CTG+UPPER(PARTNER_NAME)||PARTNER_NAME};партнеру"
   ::NumeratorRule:={{"TAX\MEMDAT.dbf","TAG_IDENT","TAG_NUM",   "DOC_NUM","SFDOC","DOC_TP + left(DTOS(REG_DATE),4)","0"},;
                     {"TAX\MEMDAT.dbf","TAG_IDENT","TAG_NUMREG","REG_NUM","SFREG","DOC_TP + left(DTOS(REG_DATE),4)","0"} } //,;
                     //{"TAX\MEMDAT.dbf","TAG_IDENT","TAG_NUMKOR","DOC_NUM","SFKORR","DOC_TP + left(DTOS(REG_DATE),4)","0"}}

   ::AddChildName( {  "clsTax_Str" ; //1 имя создаваемого класса
                   , "Tag_DOC_ID"  ; //2 TAG устанавить при открытии
                   , .T.           ; //3 MultiRecType
                   , mtNewEditDel  ; //4 ModifyType   Режимы редактирования
                   , "TAX_STR"     ; //5 название интерфейса для обращения к Chaild
                   ;      // ------ ЭТО ДЛЯ МАСТЕР-ДЕТЕИЛ ------
                   , {"DOC_ID","Tag_DOC_ID","DOC_ID",psSCOPE} ; //6
                   ;      // ------ ЭТО ДЛЯ ВСЕ ПОД ДОКУМЕНТ ------
                   , {"DOC_ID","Tag_DOC_ID","DOC_ID",psSCOPE} ; //7
                   }  )

 ::AddChildName( {  "clsTax_Book" ; //1 имя создаваемого класса
                   , "TAG_SF"         ; //2 TAG устанавить при открытии
                   , .T.                ; //3 MultiRecType
                   , mtReadOnly       ; //4 ModifyType   Режимы редактирования
                   , "BOOK"         ; //5 название интерфейса для обращения к Chaild
                   , {"DOC_ID","TAG_SF","SF_ID",psSCOPE} ; //6
                   , {"DOC_ID","TAG_SF","SF_ID",psSCOPE} ; //7
                   }  )

 ::AddChildName( {  "clsTax_Book" ; //1 имя создаваемого класса
                   , "TAG_SF"         ; //2 TAG устанавить при открытии
                   , .T.                ; //3 MultiRecType
                   , mtReadOnly       ; //4 ModifyType   Режимы редактирования
                   , "BOOKST"         ; //5 название интерфейса для обращения к Chaild
                   , {"DOC_ID","TAG_SFST","ST_SF",psSCOPE} ; //6
                   , {"DOC_ID","TAG_SFST","ST_SF",psSCOPE} ; //7
                   }  )
   /*
   ::AddChildName( {  "clsPrm_Vle" ; //1 имя создаваемого класса
                   , "TAG_DOC"         ; //2 TAG устанавить при открытии
                   , .T.                ; //3 MultiRecType
                   , mtEditOnly       ; //4 ModifyType   Режимы редактирования
                   , "PRM"         ; //5 название интерфейса для обращения к Chaild
                   , {"DOC_ID","TAG_DOC","IDDOC",psSCOPE} ; //6
                   , {"DOC_ID","TAG_DOC","IDDOC",psSCOPE} ; //7
                   }  )
    */
    GetCurrParam(@::mVAL_ID,,,@::mMainCurCode,.T.)

    //   "Bank\Doc51.Dbf" - nnoper_id, остальные - nnoper
    ::aTab := {{"Bank\Doc51.Dbf","TAG_OPER","TAG_SF","Sf_Id","0101"},;
               {"CASH\K_ORDER.DBF","TAG_OPER","TAG_SF","Sf_Id","0201"},;
               {"SCLAD\MDOC.DBF","TAG_OPER","TAG_SF","OPER_FACT","0301","SCLAD\MDOCM.DBF","TAG_FACT","TAG_OPERM","OPER_FACT"},;
               {"ZAPAS\MDOC.DBF","TAG_OPER","TAG_SF","OPER_FACT","0901","ZAPAS\MDOCM.DBF","TAG_FACT","TAG_OPERM","OPER_FACT"},;
               {"TOVAR\ACT.DBF","TAG_OPER","TAG_SF","OPER_FACT","TV01"/*1201*/,"TOVAR\ACT_OP.DBF","TAG_FACT","TAG_OPER","OPER_FACT"},;
               {"REAL\ACT.DBF","TAG_OPER","TAG_SF","OPER_FACT","0501","REAL\ACT_OP.DBF","TAG_FACT","TAG_OPER","OPER_FACT"},;
               {"PAY\FIN_DOC.Dbf","TAG_ID","TAG_SF","Sf_Id","PM01"},;
               {"PAY\FIN_DOC.Dbf","TAG_ID","TAG_SF","Sf_Id","PM02"},;
               {"Assets\res_doc.DBF","TAG_ID","TAG_SF","SRC_ID","1701","Assets\res_docs.DBF","TSSRC_ID","TAG_STR","SSRC_ID"};
                }
    ::mMultyStorno := 1

    //::mOldStrTp := ""
    //::aEditRec := {}
    ::mGroupSf := .F.
    ::mlRegDoc := .F.
    ::aMsqNotSave := {}
    ::aTabCnt := {}
RETURN self

METHOD clsTax_Inv:TAX_STR()  //
RETURN ::GetChild(1)

METHOD clsTax_Inv:BOOK
RETURN ::GetChild(2)

METHOD clsTax_Inv:BOOKST
RETURN ::GetChild(3)
/*
METHOD clsTax_Inv:PRM
RETURN ::GetChild(4)
*/
METHOD clsTax_Inv:FieldList
LOCAL s
  if Empty(::NewFieldList)
    s := ;
    'MOVE_TP;1;2;0;;;' +;
    'SFKVID;1;2;0;;;' +;
    ;//'STR_TP;1;1;0;;;' + ;
    ;//'STRTPNAME;1;20;0;;;' + ;
    'CODE_TP;1;3;0;;;' + ;
    'DOC_NUM;1;24;0;;;' +;
    'DNUM;1;40;0;;;' +;
    'SFKNUM;1;24;0;;;' +;
    'SFKDOPNUM;1;10;0;;;' +;
    'DOC_DATE;9;8;0;;;' + ;
    'SFKDATE;9;8;0;;;' + ;
    'REG_NUM;1;6;0;;;' +;
    'REG_DATE;9;8;0;;;' +;
    'MOVE_NAME;1;50;0;;;' + ;
    'ENT_NAME;1;30;0;;;' +;
    'ENT_CODE;1;6;0;;;' +;
    'ENT_ADDRNAME;1;30;0;;;' +;
    'ENT_LOCNAME;1;160;0;;;' +;
    'ENT_ADDRCODE;1;6;0;;;' +;
    'PARTNER_NAME;1;25;0;;;' +;
    'PARTNER_CODE;1;6;0;;;' +;
    'PARTNER_ADDRNAME;1;25;0;;;' +;
    'PARTNER_LOCNAME;1;160;0;;;' +;
    'PARTNER_ADDRCODE;1;6;0;;;' +;
    'VALCODE;1;3;0;;;' +;
    'VAL_RATE;6;19;5;;;' +;
    'SUM_NNDS;100;19;4;;;' +;   //6
    'SUM_NDS;100;19;4;;;' +;    //6
    'SUM_A;100;19;4;;;' + ;     //6
    'STSUM;100;19;4;;;' + ;
    'ST_SUM;100;19;4;;;' + ;
    'SUM_BOOK;100;19;4;;;' + ;
    ;//'COMMENT_m;16;4;0;;;' +;
    'COMPL_m;16;4;0;;;' +;
    'CNTVID;1;6;0;;;' +;
    'CNTNUM;1;15;0;;;' +;
    'CNTDATE;1;10;0;;;' +;
    'OBLNUM;1;6;0;;;' +;
    'ACNT_ID;1;16;0;;;' +;
    'ACNTNAME;1;80;0;;;' +;
    'ANALIT;1;60;0;;;' +;
    'ANALITNAME;1;250;0;;;' +;
    'MET_FORM;1;1;0;;;' +;
    'KOP_NDS;1;2;0;;;' +;
    'KOP_AST;1;7;0;;;' +;
    'KOP_NNDS;1;7;0;;;' +;
    'KOP_NDS0;1;7;0;;;' +;
    'KOP_AG_NDS;1;7;0;;;' +;
    'KOPNDSNAME;1;50;0;;;' +;
    'KOPASTNAME;1;50;0;;;' +;
    'KOPNNDSNAME;1;50;0;;;' +;
    'KOPNDS0NAME;1;50;0;;;' +;
    'KOPAGNDSNAME;1;50;0;;;' +;
    'X_ISMARK_;5;1;0;;;' +;
    'IS_COMB;5;1;0;;;' +;
    'SF_BRG;1;1;0;;;' +;
    'IS_FULL;5;1;0;;'
  else
    s := ::NewFieldList
  endif
RETURN s

Method clsTax_Inv:CheckBeforeEdit()
local lStorno := ((::mAliasInv)->MOVE_TP $ {'СЗ','СП'})
local  oErr ,lAv := .F.
Local nRecNo := 0,cOldTag := "", cKey := ""
Local lWr := .T. ,lRet //nRec, cAlias ,
Local cFilter
Local cAl , cMssg := ""
  begin sequence
  (::mTbInv)->(OrdSetFocus("TAG_SFMD"))
  if (::mTbInv)->(DbSeek((::cWa)->DOC_ID))
    //messagebox("Счет-фактура перевыставлен.",TITLEAPP,48)
    cMssg := "Счет-фактура перевыставлен." +  chr(13) + chr(10)
    Do while !(::mTbInv)->(Eof())
      if (::mTbInv)->SFMD_ID == (::cWa)->DOC_ID
        cMssg += (::mTbInv)->DOC_NUM + " от " + DTOC((::mTbInv)->DOC_DATE) +  chr(13) + chr(10)
      endif
      (::mTbInv)->(DbSkip(1))
    enddo
    messagebox(cMssg,TITLEAPP,48)
    Break(.F.)
  endif
  (::mTbInv)->(OrdSetFocus("TAG_SFD"))
  if (::mTbInv)->(DbSeek((::cWa)->DOC_ID))
    messagebox("По счету-фактуре есть исправительный счет-фактура.",TITLEAPP,48)
    Break(.F.)
  endif

  ::mEditValue := {}

  ::TAX_STR:GoTop()
  Do While !(::mAliasStr)->(Eof())
    if (::mAliasStr)->STR_V == "C"
      messagebox("По счету-фактуре есть откорректированные строки.",TITLEAPP,48)
      Break(.F.)
    endif
    (::mAliasStr)->(DbSkip(1))
  enddo

  if !Empty((::cWa)->SFD_ID)
    if (::cWa)->FROM_ARC
      cAl := ::GetTaxInvFrom()
    else
      cAl := ::mTbInv
    endif
    (cAl)->(OrdSetFocus("TAG_ID"))
    if !(cAl)->(DbSeek((::cWa)->SFD_ID))
      messagebox("Не найден исходный счет-фактура.",TITLEAPP,48)
      Break(.F.)
    endif
    ::mOldKorr := (cAl)->SFK_ID
  endif

  ::aStrS := {}
   if !Empty((::cWa)->SFK_ID)
     ::mOldKorr := (::cWa)->SFK_ID
     cFilter := ::TAX_STR:DbFilter()
     ::TAX_STR:Filter("")
     ::TAX_STR:GoTop()
     Do While !(::mAliasStr)->(Eof())
       if Empty((::mAliasStr)->STR_V)
         AADD(::aStrS,{(::mAliasStr)->STRS_ID,.F.})
       endif
       (::mAliasStr)->(DbSkip(1))
     enddo
     ::TAX_STR:Filter(cFilter)
     ::TAX_STR:GoTop()
   else
     ::TAX_STR:GoTop()
     Do While !(::mAliasStr)->(Eof())
       AADD(::aStrS,(::mAliasStr)->STR_ID)
       (::mAliasStr)->(DbSkip(1))
     enddo
     ::TAX_STR:GoTop()
   endif
  //pg 38454 - после аннулирования авансовый счет-фактура, так же как отгрузочный, должен быть доступен для корректировок - сейчас это сделать нельзя.
  /*
  if ((::mAliasInv)->TI_CTG == "2") .And. ((::mAliasInv)->MOVE_TP $ {'ПР','ПП'})
    lAv := .T.
    if (::mAliasInv)->IS_ANUL
      messagebox("По авансовому счету-фактуре есть анулированные записи в книге.",TITLEAPP,48)
      Break(.F.)
    endif
  endif
  */
  if len(::mParamIni) <= 0
    if !GetParamIni((::mAliasInv)->TI_CTG,lAv,@::mParamIni)
      messagebox("Не удалось инициализировать параметры настройки подсистемы КПП",TITLEAPP,48)
      Break(.F.)
    endif
  endif
  // 28908
  //if ::mParamIni[10] > (::mAliasInv)->DOC_DATE
  //  messagebox("Счет-фактура в закрытом периоде.",TITLEAPP,48)
  //  Break(.F.)
  //endif

  lRet := .F.
  if !LookUpSeek("TAX\ARC\TAX_INV.Dbf","TAG_ID",@lRet,(::cWa)->DOC_ID )
    Break(.F.)
  endif
  if lRet
    messagebox("Счет-фактура в закрытом периоде.",TITLEAPP,48)
    Break(.F.)
  endif
  if !::SetParamStrSum()
    Break(.F.)
  endif

  //::mOldStrTp := (::mAliasInv)->STR_TP
  if !::CreateDocument()
     Break(.F.)
  endif

  if !::OldCard()
    Break(.F.)
  endif
  //::mlCreateRec := .F.

  if !::mNoAddArrEdit .And. (!::BOOK:Eof() .Or. !::BOOKST:Eof())
    // Запишем если есть не аннулированные записи

    lWr := CheckNoAnulRec(::BOOK,::BOOKST)
    if lWr
      ::mEditValue := {{(::mAliasInv)->SUM_A,(::mAliasInv)->SUM_NNDS,(::mAliasInv)->SUM_NDS},{},(::mAliasInv)->DOC_NUM}
      nRecNo := (::mAliasSum)->(RecNo())
      cOldTag := (::mAliasSum)->(OrdSetFocus("TAG_TAX"))// ::TAXSUM:SetOrder("TAG_TAX")
      cKey := (::mAliasInv)->Doc_ID + (::mAliasInv)->Doc_ID
      (::mAliasSum)->(OrdScope(0,cKey))
      (::mAliasSum)->(OrdScope(1,cKey))
      (::mAliasSum)->(dbGoTop())
      do while !(::mAliasSum)->(Eof())
        AADD(::mEditValue[2],{(::mAliasSum)->TAX_ID,;
                              (::mAliasSum)->TAX_IDRT,;
                              (::mAliasSum)->TAX_RATE,;
                              (::mAliasSum)->TAX_BASE,;
                              (::mAliasSum)->TAX_SUM,;
                              .T.})
        (::mAliasSum)->(DbSkip(1))
      enddo
      (::mAliasSum)->(OrdScope(0,nil))
      (::mAliasSum)->(OrdScope(1,nil))
      (::mAliasSum)->(OrdSetFocus(cOldTag))
      (::mAliasSum)->(DbGoTo(nRecNo))
    endif
  endif
  ::mlEditStr := .F.

 recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence

Return .T.
//***********************
//PG
//  Инициализация переменных перед созданием записи в С-Ф
//  TI_CTG - 1 - закупки 2 - продажи
//  Move_Tp - Вид движения - из справочника
//  Str_Tp - Тип строк  - системный справочник
//  sPkDoc - идентификатор д-та из которого создается - для создания не из реестра С-Ф
//  DocType - Вид документа
//  Ent - идентификатор собственного предприятия
//  EntAddr - идентификатор собственного предприятия грузополучателя
//  GroupSf - флаг групповая С-Ф
//  cModId - налоговая модель
//  dDate - дата с-ф
//  lKorr - T - корректирующая с-ф
// lIspr - T исправительный если и lKorr - Т то исправительный корректировочный
//  в случае успешного выполнения - Т
method clsTax_Inv:BeforeAppend(TI_CTG, Move_Tp, sPkDoc, DocType,Ent,EntAddr,GroupSf,cModId,dDate,lKorr,lIspr )
local lAv
  //altd()
  ::mTI_CTG := TI_CTG
  ::mMove_Tp := Move_Tp
  //::mStr_Tp := Str_Tp
  ::mPkDoc := sPkDoc
  ::mDocType := DocType
  ::mEntId := Ent
  ::mEntADDRId := EntAddr
  ::mModId := cModId
  ::mDocDate := dDate
  if !(GroupSf  == nil)
    ::mGroupSf := GroupSf
  endif
  if (Upper(::mMove_Tp) $ {'ПР','ПП'})
    lAv := .T.
  else
   lAv := .F.
  endif
  if len(::mParamIni) <= 0
    if !GetParamIni(::mTI_CTG,lAv,@::mParamIni)
      messagebox("Не удалось инициализировать параметры настройки подсистемы КПП",TITLEAPP,48)
      Break(.F.)
    endif
  endif
  if Empty(::mParamIni[4])
    messagebox("Не определена налоговая модель в настройке подсистемы!",TITLEAPP,48)
    Break(.F.)
  endif

  if ValType(lKorr) == "L"
    ::mlKorr := lKorr
  endif
  if ValType(lIspr) == "L"
    ::mlIspr := lIspr
  endif

return .T.

METHOD clsTax_Inv:CheckBeforeAdd()

  if Empty(::mVAL_ID)
    if !GetCurrParam(@::mVAL_ID,,,@::mMainCurCode,.T.)
      Return .F.
    endif
  endif

RETURN .T.

Method clsTax_Inv:CheckBeforeSave()
local  oErr,sMess:={},n,i,j,cMsg //aMsgMust,
local lType := .T. //cStrTp := "", lAll,
local lTypeNew := .F.,cStrTp := "" ,nTab := 1,nJrnReg,ntbDoc  //nJrn,
Local cFieldName := "",cTbName := "",cTagDoc := "",cKeyStr := ""
Local cKeyName := "",cTagSf := "",cDocId := "",cDocStrId := "",aStr := {}
Local SetDel,lReg,tbTax,cKey//,lUnique  //lDelStr,lNewDoc,lDelDoc,
Local /*lEof := .F.,*/cJrnDoc,oStr
Local cCodeAnalit,cCodeAnalitOld //dbSfDoc,cOldSfDocTag,nRecNoSfDoc ,
Local m,k//cAlStr,aMark := {}, aDoc := {} //nDocRecNo,l ,cAlSfDoc,lNewSfDoc,
Local j101,j201,j301,j501,j901,j1201,j1701,jPM01,jPM02
Local l2 := .F.,l3 := .F.,l4 := .F.,l5 := .F.
Local aRet := {} , aStrSum := {},nRet := 0
Local nRecNo := 0,cOldTag := "",cAlias,lZac := .F.,cCntDoc
Local lRecDoc := .F., lRecNoDoc := .F. , lDocSclad := .F.,cMoveTp := ""
 begin sequence
 //altd()
 cJrnDoc := "1601"
 if !::mlRePlaceMod .And. Len(::maJrnDocDim) < 1
   if !SetJrnCode(cJrnDoc,::mAliasInv,@::maJrnDocDim)
     Break(.F.)
   endif
 endif
 if !::mlRePlaceMod .And. Len(::maJrnDocDim) > 0 .And. ::maJrnDocDim[1]
     cCodeAnalit := (::mAliasInv)->DOCDIM
     cCodeAnalitOld := cCodeAnalit
     if CheckDopParamDimRefer("DOC" + cJrnDoc,@cCodeAnalit,::oSelf)
       if !(Upper(cCodeAnalitOld) == Upper(cCodeAnalit))
         (::mAliasInv)->DOCDIM := cCodeAnalit
       endif
     endif
  endif
 ::aMsqNotSave := {}
 cMsg := ""

 //::TAX_STR:GoTop()
 oStr := ::TAX_STR
 oStr:GoTop()
 do case
   case (::mAliasInv)->SUM_A == 0 .And. ::TAX_STR:Eof()
     cMsg := "Сумма по документу равна 0. " + CRLF
     cMsg += "У счета-фактуры нет строк. "
  case (::mAliasInv)->SUM_A == 0
     cMsg := "Сумма по документу равна 0. "
  case (::mAliasStr)->(Eof()) //::TAX_STR:Eof()
     cMsg := "У счета-фактуры нет строк. "

 endcase
 if !Empty(cMsg) .And. !::mlRePlaceMod
   cMsg := cMsg + CRLF + "Продолжить сохранение?"
   if (messagebox(cMsg,TITLEAPP,36)== 7)
     Break(.F.)
   endif
 endif

 // не проверяем у строк возможность сохранения - проверяли при работе со строками
 oStr:mDocSave := .T. //::Tax_Str:mDocSave := .T.
 // Проверим строки озданные по документам

  n := (::mAliasStr)->(RecNo())
  (::mAliasStr)->(DbGoTop()) //::DS:MoveFirst()
  //aMsgSave := {}
  if !Empty((::cWa)->SFK_ID)
    cAlias := ::TAX_STR:mAliasStrS
    ::TAX_STR:Filter("")
    ::TAX_STR:GoTop()
    (cAlias)->(OrdScope(0,nil))
    (cAlias)->(OrdScope(1,nil))
  endif
  do while !(::mAliasStr)->(Eof())
    do case
      case ((::mAliasStr)->STR_TP == "2") .And. !((::cWa)->Move_Tp $ "ПР,ПП")
        l2 := .T.
      case (::mAliasStr)->STR_TP == "3" .And. !((::cWa)->Move_Tp $ "ПР,ПП")
        l3 := .T.
      case (::mAliasStr)->STR_TP == "4" .And. !((::cWa)->Move_Tp $ "ПР,ПП")
        l4 := .T.
      case (::mAliasStr)->STR_TP == "5" .And. !((::cWa)->Move_Tp $ "ПР,ПП")
        l5 := .T.
    endcase
    if (::mAliasStr)->STR_SRC //по документу
      if l2 .Or. l3
        lDocSclad := .T.
      endif
    endif
    if !Empty((::cWa)->SFK_ID)
      oStr:ValidateRecordBeforeSaveNew(.T.,.F.)
    else
      oStr:ValidateRecordBeforeSaveNew(.T.)// не выдавать сообщения на каждой записи
    endif
    if Len(oStr:aMsqNotSave) > 0
      for i := 1 to len(oStr:aMsqNotSave)
        AADD(sMess,oStr:aMsqNotSave[i])
      next
    endif

    if !Empty((::cWa)->SFK_ID)
      cKey := (::mAliasStr)->STRS_ID
      if !Empty(cKey) .And. Empty((::mAliasStr)->STR_V)
        if (cAlias)->(DbSeek(cKey))
          if (cAlias)->(DbRLock((cAlias)->(RecNo())))
            i := AScan(::aStrS,cKey)
            if i > 0
              ::aStrS[i][2] := .T.
            endif
            (cAlias)->STR_V := "C"
            if (::cWa)->From_Arc
              if (::mAliasSin)->(DbSeek((cAlias)->STR_ID))
                if (::mAliasSin)->(DbRLock((::mAliasSin)->(RecNo())))
                  (::mAliasSin)->STR_V := "C"
                  (::mAliasSin)->(DbRUnLock((::mAliasSin)->(RecNo())))
                endif
              endif
            endif
            (cAlias)->(DbRUnLock((cAlias)->(RecNo())))
          endif
        endif
      endif
    endif

    (::mAliasStr)->(DbSkip(1)) //::DS:MoveNext()
  enddo
  (::mAliasStr)->(DbGoTo(n)) //::DS:GoTo(n)
  if !Empty((::cWa)->SFK_ID)
    for i := 1 to len(::aStrS)
      if !::aStrS[i][2]
        if (cAlias)->(DbSeek(::aStrS[i][1]))
          if (cAlias)->(DbRLock((cAlias)->(RecNo())))
            (cAlias)->STR_V := " "
            if (::cWa)->From_Arc
              if (::mAliasSin)->(DbSeek((cAlias)->STR_ID))
                if (::mAliasSin)->(DbRLock((::mAliasSin)->(RecNo())))
                  (::mAliasSin)->STR_V := " "
                  (::mAliasSin)->(DbRUnLock((::mAliasSin)->(RecNo())))
                endif
              endif
            endif
            (cAlias)->(DbRUnLock((cAlias)->(RecNo())))
          endif
        endif
      endif
    next
    ::TAX_STR:Filter("STR_V == 'P'")
  endif

 ////////////

  //проверяем обязательные и зависимые поля

 if Empty((::mAliasInv)->TI_CTG)
   AADD(sMess,"Не определена категория счета-фактуры!")
 endif
 if Empty((::mAliasInv)->MOVE_TP)
   AADD(sMess,"Не определен вид движения счета-фактуры!")
 endif
 if Empty((::mAliasInv)->DOC_TP)
    AADD(sMess,"Не определен тип документа!")
 endif
 if !Empty((::mAliasInv)->DOC_NUM) .Or. !Empty((::mAliasInv)->REG_NUM)
   //tbTax := CreateDbRecord(B6_DBF_PATH + "Tax\Tax_inv.Dbf")
   if ! _DbAreaOpen(B6_DBF_PATH + "Tax\Tax_inv.Dbf", @tbTax,"TAG_NUM")
      Break(.F.)
    endif
 endif

 if Empty((::mAliasInv)->DOC_DATE)
   AADD(sMess,"Не определена дата счета-фактуры!")
 endif
 // pg 29370
 //  pg 30312
 if (::mAliasInv)->KORR .Or. (::mAliasInv)->DEF
   if (::mParamIni[10] > (::mAliasInv)->DOC_DATE)
     if (::mAliasInv)->KORR
       AADD(sMess,"Дата корректировочного счет-фактуры меньше даты начала работы приложения книга покупок-продаж.")
     else
       AADD(sMess,"Дата исправительного счет-фактуры меньше даты начала работы приложения книга покупок-продаж.")
     endif
   endif
 else

 if !::mlRePlaceMod .And. (::mParamIni[10] > (::mAliasInv)->DOC_DATE) .And. ::mlHandSum /*((::mAliasInv)->MOVE_TP $ "ПР,ПП") .And. (::mParamIni[10] > (::mAliasInv)->DOC_DATE)*/
   if (::mAliasInv)->SUM_BOOK = 0
     if (::mAliasInv)->MOVE_TP $ "ПР,ПП"
       aRet :=  RunForm('tax\frmTaxAvSum',.T.,{(::mAliasInv)->SUM_A,0,(::mAliasInv)->SUM_A,.T.,0,0},,.T.)
       if len(aRet) > 0
         if aRet[1] > 0
           (::mAliasInv)->SUM_BOOK := aRet[1]
           (::mAliasInv)->SUM_PAY := aRet[1]
           if (::mAliasInv)->SUM_BOOK == (::mAliasInv)->SUM_A
             (::mAliasInv)->IS_FULL := .T.
           endif
         endif
         if aRet[2] > 0
           (::mAliasInv)->ST_SUM := aRet[2]
         endif
       endif
     else
       aRet :=  RunForm('tax\frmTaxAvSum',.T.,{0,0,(::mAliasInv)->SUM_A,.F.,0,0},,.T.)
       if len(aRet) > 0
         if aRet[1] > 0
           (::mAliasInv)->SUM_BOOK := aRet[1]
           (::mAliasInv)->SUM_SHP := aRet[1]
           if (::mAliasInv)->SUM_BOOK == (::mAliasInv)->SUM_A
             (::mAliasInv)->IS_FULL := .T.
           endif
         endif
       endif
     endif
   endif
   //AADD(sMess,"Дата счет-фактуры меньше даты начала работы приложения книга покупок-продаж.")
 endif

 endif

 If !Empty((::mAliasInv)->REG_DATE)
   if (::mAliasInv)->REG_DATE < (::mAliasInv)->DOC_DATE
     AADD(sMess,'Дата регистрации меньше даты документа!')
   endif
 endif

 if Empty((::mAliasInv)->DOC_NUM)
   AADD(sMess,"Не определен номер счета-фактуры!")
 elseif !Empty((::mAliasInv)->DOC_DATE)
 // Проверить уникальность
   if !::CheckUniqueNum(.F.,@cMsg)
     AADD(sMess,cMsg)
   endif
 endif
 if Empty((::mAliasInv)->REG_NUM)
   AADD(sMess,"Не определен регистрационный номер счета-фактуры!")
 elseif !Empty((::mAliasInv)->REG_DATE)
   if !::CheckUniqueNum(.T.,@cMsg)
     AADD(sMess,cMsg)
   endif
 endif

 if Empty((::mAliasInv)->ENT_ID)
   AADD(sMess,"Не определено собственное предприятие счета-фактуры!")
 endif
 if Empty((::mAliasInv)->PRT_ID)
   AADD(sMess,"Не определен партнер счета-фактуры!")
 endif
 if !((::mAliasInv)->PRT_TP $ "1,2")
     AADD(sMess,"тип партнера счета-фактуры должен быть партнер или сотрудник!")
 else
   if ((::mAliasInv)->PRT_TP == "2") .And. ((::mAliasInv)->TI_CTG == "1")
     AADD(sMess,"тип партнера приходного счета-фактуры должен быть партнер!")
   endif
 endif

 if !::CheckObl()
     AADD(sMess,"не введен этап договора!")
 endif

 if (::mAliasInv)->IS_COMB
   if Empty((::mAliasInv)->SFMD_ID) .And. Empty((::mAliasInv)->MD_ID)
     AADD(sMess,"в сводном счете-фактуре  должны быть заполнены поля группы Посредник")
   endif
 endif

 /*
 // Проверяем обязательные параметры
  aMsgMust := {}
  if CheckMustPrm(::PRM,@aMsgMust)
    n := len(aMsgMust)
    if n > 0
      for i := 1 to n
        AADD(sMess,aMsgMust[i])
      next
    endif
  else
    messagebox("Не удалось проверить дополнительные параметры! Повторите сохранение!",TITLEAPP,16)
    Break(.F.)
  endif
  // Проверяем обязательные измерения
  aMsgMust := {}
 */
 if len(sMess)>0
   ::aMsqNotSave :=  sMess
   Break(.F.)
 endif
 //////////
 // Если комментарий к строке пустой - удалим строку
 cAlias  := oStr:CommentM:cWa
 (cAlias)->(DbGoTop())
 do while !(cAlias)->(Eof())
   if Empty((cAlias)->Comment) .And.;
      Empty((cAlias)->QDOPCHAR1) .And.;
      Empty((cAlias)->QDOPCHAR2) .And.;
      Empty((cAlias)->QDOPCHAR3) .And.;
      Empty((cAlias)->QDOPCHAR4) .And.;
      Empty((cAlias)->QDOPNUM1) .And.;
      Empty((cAlias)->QDOPNUM2) .And.;
      Empty((cAlias)->QDOPDATA1) .And.;
      Empty((cAlias)->QDOPDATA2) .And.;
      Empty((cAlias)->KOLFREE)

      if (cAlias)->(DbRLock((cAlias)->(RecNo())))
        (cAlias)->(DbDelete())
        (cAlias)->(DbRUnLock((cAlias)->(RecNo())))
      endif

   endif
   (cAlias)->(DbSkip(1))
 enddo
 //////////
 k := len(::mEditValue)
 // mlRePlaceMod init .F.  // При замене налоговой модели сохраняем если изменились параметрыс-ф
 // mlReCreateBook
 ::mlReCreateBook := .F.
 if k > 0
   //Проверим изменение сумм по с-ф при редактировании
   if !::BOOK:Eof() .Or. !::BOOKST:Eof()
     //48934
     //Если  внесены изменения в любые строки
     //счета-фактуры, то при сохранении с-ф или
     //при попытке создать любую регистрационную записи по с-ф  определяется  наличие по нему записей в книгу

     if lDocSclad .And. ::mlEditStr
       if ::mlRePlaceMod
         ::mlReCreateBook := .T.
       else
         ::BOOK:GoTop()
         Do While !::BOOK:Eof()
           if Empty(::BOOK:SRC_ID)
             lRecNoDoc := .T.
             if !( ::BOOK:REC_TP $ cMoveTp)
               if !Empty(cMoveTp)
                 cMoveTp += chr(13) + chr(10)
               endif
               cMoveTp += ::BOOK:REC_TP + "  " + AllTrim(::BOOK:RECNAME())
             endif
           else
             lRecDoc := .T.
           endif
           ::BOOK:Skip(1)
         enddo
         Do While !::BOOKST:Eof()
           if Empty(::BOOKST:SRC_ID)
             lRecNoDoc := .T.
             if !( ::BOOKST:REC_TP $ cMoveTp)
               cMoveTp += chr(13) + chr(10)
               cMoveTp += ::BOOKST:REC_TP + "  " + ::BOOKST:RECNAME()
             endif
           else
             lRecDoc := .T.
           endif
           ::BOOKST:Skip(1)
         enddo
         cMsg := "По счет - фактуре на основе первичных документов" + chr(13) + chr(10)
         cMsg += "сформированы записи в книгу покупок( продаж)." + chr(13) + chr(10)
         cMsg += "После внесения изменений в счет-фактуру их данные стали неверными"

         if lRecDoc
           nRet := nRet := D_CUSTOMMSG("Внимание",cMsg,"'Переформировать' 0 'Удалить' 1 ",0,.T.)
           if nRet == 0
             if !CanEditProvodka(.F.)
               RightMessage()
               Break(.F.)
             endif
             ::mDelRecBook := .F.
           else
             if !CanDeleteProvodka(.T.)
               Break(.F.)
             endif
             ::mDelRecBook := .T.
           endif
         endif

         if !Empty(cMoveTp)
           cMsg := "По счету-фактуре  есть записи без" + chr(13) + chr(10) +  "первичных документов:" + chr(13) + chr(10)
           cMsg += cMoveTp + chr(13) + chr(10)
           cMsg += "Они будут удалены." + chr(13) + chr(10) + "Их необходимо переформировать вручную."
           messagebox(cMsg,TITLEAPP,48)
         endif
         ::mDelBook := .T.
       endif
     else

       if !(::mEditValue[1][1] == (::mAliasInv)->SUM_A .And. ;
            ::mEditValue[1][2] == (::mAliasInv)->SUM_NNDS .And.;
            ::mEditValue[1][3] == (::mAliasInv)->SUM_NDS)
          if ::mlRePlaceMod
            ::mlReCreateBook := .T.
          else
            if len(::aMsqNotSave) > 0
              AADD(::aMsqNotSave,"По счету-фактуре созданы записи в книгу. Их необходимо удалить.")
              Break(.F.)
            else
              if ::mDelRecBook
                ::mDelBook := .T.
              else
                if messagebox("По счету-фактуре созданы записи в книгу." + chr(13) + chr(10) + "Их необходимо удалить."+ chr(13) + chr(10) +"Удалить?",TITLEAPP,36) == 6
                  if !CanDeleteProvodka(.T.)
                    Break(.F.)
                  endif
                  ::mDelBook := .T.
                else
                  Break(.F.)
                endif
              endif
            endif
          endif
       endif
       nRecNo := (::mAliasSum)->(RecNo())
       cOldTag := (::mAliasSum)->(OrdSetFocus("TAG_TAX"))// ::TAXSUM:SetOrder("TAG_TAX")
       cKey := (::mAliasInv)->Doc_ID + (::mAliasInv)->Doc_ID
       (::mAliasSum)->(OrdScope(0,cKey))
       (::mAliasSum)->(OrdScope(1,cKey))
       (::mAliasSum)->(dbGoTop())
       j := 0
       k := len(::mEditValue[2])
       aStrSum := {}
       do while !(::mAliasSum)->(Eof())
         j := j +1
         for m := 1 to k
           if ::mEditValue[2][m][1] == (::mAliasSum)->TAX_ID .And.;
              ::mEditValue[2][m][2] == (::mAliasSum)->TAX_IDRT .And.;
              ::mEditValue[2][m][3] == (::mAliasSum)->TAX_RATE .And.;
              ::mEditValue[2][m][4] == (::mAliasSum)->TAX_BASE .And.;
              ::mEditValue[2][m][5] == (::mAliasSum)->TAX_SUM
              ::mEditValue[2][m][6] := .F.
              exit
           endif
         next
         (::mAliasSum)->(DbSkip(1))
       enddo
       (::mAliasSum)->(OrdScope(0,nil))
       (::mAliasSum)->(OrdScope(1,nil))
       (::mAliasSum)->(OrdSetFocus(cOldTag))
       (::mAliasSum)->(DbGoTo(nRecNo))

       if j <> k // добавилась или удалилась строка подналог
         if ::mlRePlaceMod
           ::mlReCreateBook := .T.
         else
           if len(::aMsqNotSave) > 0
              AADD(::aMsqNotSave,"По счету-фактуре созданы записи в книгу. Их необходимо удалить.")
              Break(.F.)
           else
             if ::mDelRecBook
                ::mDelBook := .T.
             endif
             if !::mDelBook
               if messagebox("По счету-фактуре созданы записи в книгу." + chr(13) + chr(10) + "Их необходимо удалить."+ chr(13) + chr(10) +"Удалить?",TITLEAPP,36) == 6
                 if !CanDeleteProvodka(.T.)
                   Break(.F.)
                 endif
                 ::mDelBook := .T.
               else
                 Break(.F.)
               endif
             endif
           endif
           //AADD(::aMsqNotSave,"По счету-фактуре созданы записи в книгу. Их необходимо удалить.")
           //::mDelBook := .T.
           //Break(.F.)
         endif
       endif
       for m := 1 to k
          if ::mEditValue[2][m][6]
            if ::mlRePlaceMod
              ::mlReCreateBook := .T.
            else
              //AADD(::aMsqNotSave,"По счету-фактуре созданы записи в книгу. Их необходимо удалить.")
              //::mDelBook := .T.
              //Break(.F.)
              if len(::aMsqNotSave) > 0
                AADD(::aMsqNotSave,"По счету-фактуре созданы записи в книгу. Их необходимо удалить.")
                Break(.F.)
              else
                if ::mDelRecBook
                   ::mDelBook := .T.
                endif
                if !::mDelBook
                  if messagebox("По счету-фактуре созданы записи в книгу." + chr(13) + chr(10) + "Их необходимо удалить."+ chr(13) + chr(10) +"Удалить?",TITLEAPP,36) == 6
                    if !CanDeleteProvodka(.T.)
                      Break(.F.)
                    endif
                    ::mDelBook := .T.
                  else
                    Break(.F.)
                  endif
                endif
              endif
            endif
          endif
       next

     endif
      if !::BOOK:Eof() .Or. !::BOOKST:Eof()
        if !(::mEditValue[3] == (::mAliasInv)->DOC_NUM)
         //Нужно внести изменения в книгу если там есть записи
           if !::Book:Eof()
             cAlias := ::Book:Ds:Alias()
             if (cAlias)->(DbRLock((cAlias)->(RecNo())))
               (cAlias)->SF_NUM := (::mAliasInv)->DOC_NUM
             else
               AADD(::aMsqNotSave,"Не удалось изменить в записи в книгу номер счета-фактуры.")
               Break(.F.)
             endif
           endif
           if !::BookSt:Eof()
             cAlias := ::BookSt:Ds:Alias()
             if (cAlias)->(DbRLock((cAlias)->(RecNo())))
               (cAlias)->ST_NUM := (::mAliasInv)->DOC_NUM
             else
               AADD(::aMsqNotSave,"Не удалось изменить в записи в книгу номер счета-фактуры.")
               Break(.F.)
             endif
           endif
        endif
      endif
   endif
 endif

      /////////////
 //создание или синхронизация карточки
 ////////////
   if /*!_IS_UDAL  .And.*/ !(::mAliasInv)->MOVE_TP $ {"ПП","ПР"}
     if !::CheckCard()
       Break(.F.)
     endif
   endif

   m := len(::aSFDOC)
   j101 := j201 := j301 := j501 := j901 := j1201 := j1701 := jPM01 := jPM02 := 0
   if m > 0
     j := len(::maTbDoc)
     // нужно произвести отметки в связанных документах
     //Отсортируем по журналу и д-ту сначала строки и последний сам документ
     ::aSFDOC := ASort(::aSFDOC,,,{|aX,aY|aX[_KEY] > aY[_KEY]})
     cKey := " "
     nJrnReg := "" //0
     for k := 1 to m
         if !(cKey == ::aSFDOC[k][_DOCID])
           lReg := .F.
           cKey := ::aSFDOC[k][_DOCID]
           if !(nJrnReg == ::aSFDOC[k][_JRNID])

             nJrnReg := ::aSFDOC[k][_JRNID]
             do case
               case nJrnReg == "0101"
                 if j101 == 0
                   j101 := 1
                 endif
               case nJrnReg == "0201"
                 if j201 == 0
                   j201 := 1
                 endif
               case nJrnReg == "0301"
                 if j301 == 0
                   j301 := 1
                 endif
               case nJrnReg == "0501"
                 if j501 == 0
                   j501 := 1
                 endif
               case nJrnReg == "0901"
                 if j901 == 0
                   j901 := 1
                 endif
               case nJrnReg == "TV01"//1201
                 if j1201 == 0
                   j1201 := 1
                 endif
               case nJrnReg == "PM01"
                 if jPM01 == 0
                   jPM01 := 1
                 endif
               case nJrnReg == "PM02"
                 if jPM02 == 0
                   jPM02 := 1
                 endif
               case nJrnReg == "1701"
                 if j1701 == 0
                   j1701 := 1
                 endif
             endcase
             for ntbDoc := 1 to j
               if nJrnReg == ::maTbDoc[ntbDoc][1]
                 (::maTbDoc[ntbDoc][2])->(WaEdit())
                 AADD(::maTran,::maTbDoc[ntbDoc][2])
                 if !(nJrnReg $ {"0101","0201","PM01","PM02"})

                   (::maTbDoc[ntbDoc][5])->(WaEdit())
                   AADD(::maTran,::maTbDoc[ntbDoc][5])
                 endif
                 Exit
               endif
             next

             for nTab := 1 to len(::aTab)
               if nJrnReg == ::aTab[nTab][5]
                 exit
               endif
             next
             (::maTbDoc[ntbDoc][2])->(OrdSetFocus(::aTab[nTab][2]))
             if !(nJrnReg $ {"0101","0201","PM01","PM02"})
               (::maTbDoc[ntbDoc][5])->(OrdSetFocus(::aTab[nTab][8]))
             endif
           endif
         endif

         if nJrnReg $ {"0101","0201","PM01","PM02"} // без строк
           if ::aSFDOC[k][_STATUS] == 1 .And. ::aSFDOC[k][_DEL] == .F.
           // Отметим новый
              if (::maTbDoc[ntbDoc][2])->(DbSeek(cKey))
                (::maTbDoc[ntbDoc][2])->&(::aTab[nTab][4]) := ::aSFDOC[k][_SFID]
              endif
           endif
           if !(::aSFDOC[k][_STATUS] == 1) .And. ::aSFDOC[k][_DEL] == .T.
           // Удалим отметку в старом
             if (::maTbDoc[ntbDoc][2])->(DbSeek(cKey))
               (::maTbDoc[ntbDoc][2])->&(::aTab[nTab][4]) := Space(22)
             endif
           endif
         else // со строками
           if ::aSFDOC[k][_DOCID] == ::aSFDOC[k][_DOCSTRID]
           //Документ
             if lReg
             //Есть строки которые зарегистрировали
               if ::aSFDOC[k][_STATUS] == 1
               // новый документ нужно зарегистрировать
                 if (::maTbDoc[ntbDoc][2])->(DbSeek(cKey))
                   (::maTbDoc[ntbDoc][2])->&(::aTab[nTab][4]) := ::aSFDOC[k][_SFID]
                   if nJrnReg == "1701"
                     cCntDoc := (::maTbDoc[ntbDoc][2])->CNT_DOC_ID
                     if Empty(cCntDoc) .And. ::CardYes()
                       (::maTbDoc[ntbDoc][2])->CNT_DOC_ID := (::mAliasInv)->DOC_ID
                       (::maTbDoc[ntbDoc][2])->CNT_TYPE := "3"
                     endif
                   endif
                 endif
               endif
             else
             //нет зарегистрированных строк
               if !(::aSFDOC[k][_STATUS] == 1)
               // документ старый - нужно разрегистрировать
                 if (::maTbDoc[ntbDoc][2])->(DbSeek(cKey))
                   (::maTbDoc[ntbDoc][2])->&(::aTab[nTab][4]) := Space(22)
                   if nJrnReg == "1701"
                     cCntDoc := (::maTbDoc[ntbDoc][2])->CNT_DOC_ID
                     if !Empty(cCntDoc)
                       if cCntDoc == (::mAliasInv)->DOC_ID
                         (::maTbDoc[ntbDoc][2])->CNT_DOC_ID := ""
                         (::maTbDoc[ntbDoc][2])->CNT_TYPE := ""
                       endif
                     endif
                   endif
                   ::aSFDOC[k][_DEL] := .T.
                 endif
               endif
             endif
           else
             if ::aSFDOC[k][_STATUS] == 1 .And. ::aSFDOC[k][_DEL] == .F.
             // Добавилась строка и не удаленная
               lReg := .T.
               if (::maTbDoc[ntbDoc][5])->(DbSeek(::aSFDOC[k][_DOCSTRID]))
                  if (::maTbDoc[ntbDoc][5])->(DbRlock())
                    (::maTbDoc[ntbDoc][5])->&(::aTab[nTab][9]) := ::aSFDOC[k][_SFSTRID]
                    (::maTbDoc[ntbDoc][5])->(DbRUnlock((::maTbDoc[ntbDoc][5])->(RecNo())))
                  endif
               endif
             endif
             if !(::aSFDOC[k][_STATUS] == 1)
               if ::aSFDOC[k][_DEL] == .F.
                 lReg := .T.
                 if ::aSFDOC[k][_STATUS] == 3
                 // строку перевыбрали - нужно перерегистрить
                   if (::maTbDoc[ntbDoc][5])->(DbSeek(::aSFDOC[k][_DOCSTRID]))
                     if (::maTbDoc[ntbDoc][5])->(DbRlock())
                       (::maTbDoc[ntbDoc][5])->&(::aTab[nTab][9]) := ::aSFDOC[k][_SFSTRID]
                       (::maTbDoc[ntbDoc][5])->(DbRUnlock((::maTbDoc[ntbDoc][5])->(RecNo())))
                     endif
                   endif
                 endif
               else
               // строку нужно разрегистрить
                 if (::maTbDoc[ntbDoc][5])->(DbSeek(::aSFDOC[k][_DOCSTRID]))
                   if (::maTbDoc[ntbDoc][5])->(DbRlock())
                     (::maTbDoc[ntbDoc][5])->&(::aTab[nTab][9]) := Space(22)
                     (::maTbDoc[ntbDoc][5])->(DbRUnlock((::maTbDoc[ntbDoc][5])->(RecNo())))
                   endif
                 endif
               endif
             endif
           endif
         endif

     next
   endif


   if /*!_IS_UDAL  .And.*/ !(::mAliasInv)->MOVE_TP $ {"ПП","ПР"}  .And. ::CardYes()
    // Проверяем регистацию документов
     if !(ValType(::mTbApReg) == "O")
       ::mTbApReg := CreateDbRecord(B6_DBF_PATH + "AP_REG.dbf", "CDPS")
     endif

     (::mTbApReg:Alias)->(WaEdit())
     AADD(::maTran,::mTbApReg:Alias)

     if ( ::mTbCard:Alias )->(waEditLevel()) < 1 //( ::mTbCard:Alias ) < 1
       (::mTbCard:Alias)->(WaEdit())
       AADD(::maTran,::mTbCard:Alias)
     endif

     if !::RegDocForSF()
       Break(.F.)
     endif
   endif

   (::mAliasInv)->STR_TP2 := l2
   (::mAliasInv)->STR_TP3 := l3
   (::mAliasInv)->STR_TP4 := l4
   (::mAliasInv)->STR_TP5 := l5
   if (::mAliasInv)->Sum_Book == (::mAliasInv)->Sum_A
      (::mAliasInv)->IS_FULL := .T.
    else
      (::mAliasInv)->IS_FULL := .F.
    endif
   Break(.T.)
 recover using oErr

  _DbAreaClose(tbTax)
  if !Empty(SetDel)
    Set(SetDel)
  endif
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence

Return .T.


Method clsTax_Inv:CheckBeforeDel()
local  oErr
Local m,j,k,cMsg := ""//i,r,cBookSrcId := "",cBookStSrcId := "" //nJrn,n,
//Local cTbName,cTagDoc,cTagSf,cFieldName,cKeyName,cKeyStr
//Local dbSfDoc,cAlSfDoc,l,cAlStr
Local cKey,nJrnReg,nTbDoc,nTab ,cCntDoc
//local cFieldName
 begin sequence
 //altd()
  (::mTbInv)->(OrdSetFocus("TAG_SFD"))
  if (::mTbInv)->(DbSeek((::cWa)->DOC_ID))
    messagebox("По счету-фактуре есть исправительный счет-фактура.",TITLEAPP,48)
    Break(.F.)
  endif

  ::TAX_STR:GoTop()
  Do While !(::mAliasStr)->(Eof())
    if (::mAliasStr)->STR_V == "C"
      messagebox("По счету-фактуре есть откорректированные строки.",TITLEAPP,48)
      Break(.F.)
    endif
    (::mAliasStr)->(DbSkip(1))
  enddo
  ::Tax_Str:mDocDelete := .T.
   //for i := 1 to len(::maTbStr)
   //  _DbAreaClose(::maTbStr[i])
   //next
   //::maTbStr := {}
   //if ::mNew
   //  Break(.T.)
   //endif
    /*
   if !::BOOK:EOF() .Or. !::BOOKST:EOF()
     cMsg += "По счету-фактуре есть регистрационные записи в книгу." + CRLF
     cMsg += "Вместе со счетом-фактурой будут удалены записи в книге." + CRLF
     cMsg += "Удалить счет-фактуру?"
     r :=messagebox(cMsg,TITLEAPP,36)
     if !(r == 6)
       Break(.F.)
     endif
     if !::BOOK:EOF()
       cBookSrcId := ::BOOK:SRC_ID
       ::BOOK:lSfDel := .T.
     endif
     if !::BOOKST:EOF()
       cBookStSrcId := ::BOOKST:SRC_ID
       ::BOOKST:lSfDel := .F.
     endif

   endif
   */
   If !::CreateDocument()
     Break(.F.)
   endif

   // Удалим если нужно карточку созданную по с-ф
   //if !_IS_UDAL
     if !DelCardBrg((::mAliasInv)->DOC_ID  )
       Messagebox("По счету/фактуре существует карточка расчета с партнером. Удалить документ нельзя",TITLEAPP,48)
       Break(.F.)
     endif
   //endif
   m := len(::aSFDOC)

   if m > 0
     j := len(::maTbDoc)
     // нужно произвести отметки в связанных документах
     //Отсортируем по журналу и д-ту сначала строки и последний сам документ
     ::aSFDOC := ASort(::aSFDOC,,,{|aX,aY|aX[_KEY] < aY[_KEY]})
     cKey := " "
     nJrnReg := "" //0
     for k := 1 to m
         if !(cKey == ::aSFDOC[k][_DOCID])
           cKey := ::aSFDOC[k][_DOCID]
           if !(nJrnReg == ::aSFDOC[k][_JRNID])

             nJrnReg := ::aSFDOC[k][_JRNID]

             for ntbDoc := 1 to j
               if nJrnReg == ::maTbDoc[ntbDoc][1]
                 (::maTbDoc[ntbDoc][2])->(WaEdit())
                 AADD(::maTran,::maTbDoc[ntbDoc][2])
                 if !(nJrnReg $ {"0101","0201","PM01","PM02"})
                   (::maTbDoc[ntbDoc][5])->(WaEdit())
                   AADD(::maTran,::maTbDoc[ntbDoc][5])
                 endif
                 Exit
               endif
             next

             for nTab := 1 to len(::aTab)
               if nJrnReg == ::aTab[nTab][5]
                 exit
               endif
             next
             (::maTbDoc[ntbDoc][2])->(OrdSetFocus(::aTab[nTab][2]))
             if !(nJrnReg $ {"0101","0201","PM01","PM02"})
               (::maTbDoc[ntbDoc][5])->(OrdSetFocus(::aTab[nTab][8]))
             endif
           endif
         endif

         if ::aSFDOC[k][_DOCID] == ::aSFDOC[k][_DOCSTRID]
            // документ старый - нужно разрегистрировать
              if (::maTbDoc[ntbDoc][2])->(DbSeek(cKey))
                 (::maTbDoc[ntbDoc][2])->&(::aTab[nTab][4]) := Space(22)
                 if nJrnReg == "1701"
                   cCntDoc := (::maTbDoc[ntbDoc][2])->CNT_DOC_ID
                   if !Empty(cCntDoc)
                     if cCntDoc == (::mAliasInv)->DOC_ID
                       (::maTbDoc[ntbDoc][2])->CNT_DOC_ID := ""
                       (::maTbDoc[ntbDoc][2])->CNT_TYPE := ""
                     endif
                   endif
                 endif
              endif

         else
             // строку нужно разрегистрить
             if (::maTbDoc[ntbDoc][5])->(DbSeek(::aSFDOC[k][_DOCSTRID]))
                if (::maTbDoc[ntbDoc][5])->(DbRlock())
                  (::maTbDoc[ntbDoc][5])->&(::aTab[nTab][9]) := Space(22)
                  (::maTbDoc[ntbDoc][5])->(DbRUnlock((::maTbDoc[ntbDoc][5])->(RecNo())))
                endif
             endif

         endif

     next
   endif
   /*
   dbSfDoc := ::SFDOC:DS
   cAlSfDoc := dbSfDoc:Alias()
   // Есть документы по с-ф
   dbSfDoc:SetOrder("TAG_SFDOC")
   dbSfDoc:Scope((::mAliasInv)->DOC_ID,(::mAliasInv)->DOC_ID,"TAG_SFDOC")
   dbSfDoc:GoTop()
   if !dbSfDoc:Eof()
      if len(::maTbDoc) < 1
        if !::CreateDocument()
          Break(.F.)
        endif
      endif
   endif
   nJrn := 0
   Do While !dbSfDoc:Eof()
   // Это документ
     if (cAlSfDoc)->DOC_ID == (cAlSfDoc)->DOCSTR_ID

       if !(nJrn == (cAlSfDoc)->JRN_ID)
          nJrn := (cAlSfDoc)->JRN_ID
         // Определяем для журнала параметры нахождения строк документа
          For i := 1 to len(::maTbDoc)
            if nJrn == ::maTbDoc[i][1]
              if !(::maTbDoc[i][1] $ {101,201})
                if !::SetStrDoc(nJrn,@cTbName,@cTagDoc,@cTagSf,@cFieldName,@cKeyName,@cKeyStr)
                  Break(.F.)
                endif
                if ! _DbAreaOpen(B6_DBF_PATH + cTbName, @cAlStr,cTagDoc)
                  break(.F.)
                endif
                AADD(::maTbStr,cAlStr)
              endif
              Exit
            endif
          next

         for n := 1 to len(::aTab)
           if nJrn == ::aTab[n][5]
             exit
           endif
         next
       endif
       if !(nJrn $ {101,201})
         //Документы имеют строки
         l := len(::maTbStr)
         IF !::ClearMarkForStrDocm((cAlSfDoc)->DOC_ID,cTbName,cTagDoc,cFieldName,,,::maTbStr[l])
            Break(.F.)
         ENDIF
       endif
       if ::maTbDoc[i][2]:Seek((cAlSfDoc)->DOC_ID,.T.,::aTab[n][2])
         ::maTbDoc[i][2]:FieldValue(::aTab[n][4],Space(22))
         if cBookStSrcId == (cAlSfDoc)->DOC_ID
           ::BOOKST:mTbDocFromSf := ::maTbDoc[i][2]
           ::BOOKST:nRecNoDocFromSf := ::maTbDoc[i][2]:RecNo()

         endif
         if cBookSrcId == (cAlSfDoc)->DOC_ID
           ::BOOK:mTbDocFromSf := ::maTbDoc[i][2]
           ::BOOK:nRecNoDocFromSf := ::maTbDoc[i][2]:RecNo()

         endif
       endif
     endif
     dbSfDoc:Skip(1)
   enddo
   */

   Break(.T.)
 recover using oErr

  if valtype(oErr) == "L"
     return oErr
   else

     return .F.
  endif
 end sequence

Return .T.

METHOD clsTax_Inv:DOC_ID(value)
  IF (NIL <> value .AND. 0 <> ::EditMode)
    ::DS:FieldValue("DOC_ID", value)
  ENDIF
RETURN (::mAliasInv)->DOC_ID //::DS:DOC_ID

METHOD clsTax_Inv:TI_CTG(value)    // C(01)    Категория счета-фактуры
  IF (NIL <> value .AND. 0 <> ::EditMode)
    IF value $ {'1','2'}
      ::DS:FieldValue("TI_CTG", value)
    ELSE
      MessageBox('Неверна категория счет-фактуры',TITLEAPP,48)
    ENDIF
  ENDIF
RETURN (::mAliasInv)->TI_CTG

METHOD clsTax_Inv:MOVE_TP(value)   // C(02)    Вид движения счета-фактуры
  IF (NIL <> value .AND. 0 <> ::EditMode)
    ::DS:FieldValue("MOVE_TP", value)
  ENDIF
RETURN (::mAliasInv)->MOVE_TP
/*
METHOD clsTax_Inv:STR_TP(value)    // C(01)    Тип строк
  IF (NIL <> value .AND. 0 <> ::EditMode)
    ::DS:FieldValue("STR_TP",value)
  ENDIF
RETURN (::mAliasInv)->STR_TP
*/
/*
METHOD clsTax_Inv:STRTPNAME()    // C(20)    Тип строк
local s := ""
  if (::STPTP)->(DbSeek((::mAliasInv)->STR_TP))
    s :=  (::STPTP)->STR_NAME
  endif
RETURN s
 */
METHOD clsTax_Inv:DOC_TP(value)    // N(10,0)  Вид документа
local OldTp
  IF (NIL <> value .AND. 0 <> ::EditMode)
    //altd()
    OldTp := (::mAliasInv)->DOC_TP
    if value <>OldTp
      //::DS:FieldValue("DOC_TP", value)
      if !Empty(value) .And. (::ObjDOC_TYPE)->(DbSeek(value))
        ::DS:FieldValue("DOC_TP", value)
        ::DS:FieldValue("CODE_TP", (::ObjDOC_TYPE)->CODEDT)
        //(::mAliasInv)->CODE_TP := (::ObjDOC_TYPE)->CODEDT
      else
          //(::mAliasInv)->CODE_TP := ""
        ::DS:FieldValue("DOC_TP", "")
        ::DS:FieldValue("CODE_TP", "")
        RETURN (::mAliasInv)->DOC_TP
      endif

      //GetParamForDocType(::PRM,(::mAliasInv)->DOC_TP,"1601")
      if (::mAliasInv)->TI_CTG == "2" .And. !(::mAliasInv)->DEF
        ::GetNextNumInv(.F.)
      endif
      ::GetNextNumInv(.T.)
    endif
  ENDIF
RETURN (::mAliasInv)->DOC_TP

METHOD clsTax_Inv:CODE_TP()
RETURN (::mAliasInv)->CODE_TP

METHOD clsTax_Inv:DOC_NUM(value)   // C(06)    Номер документа
Local nLen
  IF (NIL <> value .AND. 0 <> ::EditMode)
    if !::IsGenDocNum
        nLen := ::LenNum()
        if (::mAliasInv)->TI_CTG == "2" //.Or. (::mAliasInv)->DEF
          value := Padr(Alltrim(value),nLen)
          value := ObrabotkaNom(value,{,,nLen}, .T.)
        else
          value := SUBSTR(value,1,nLen)//Padl(value,nLen)
        endif
    endif
    ::DS:FieldValue("DOC_NUM", value)
    ::RaiseEvent("TaxInvNumChanged")
  ENDIF
RETURN (::mAliasInv)->DOC_NUM

METHOD clsTax_Inv:DOC_DATE(value)  // D        Дата документа
local OldYear
  IF (NIL <> value .AND. 0 <> ::EditMode)
    //pg 29370
    //if !Empty(value) .And. ((::mAliasInv)->MOVE_TP $ "ПР,ПП") .And. (::mParamIni[10] > value)
    //  messagebox("Дата счет-фактуры меньше даты начала работы приложения книга покупок-продаж.",TITLEAPP,48)
    //else
      OldYear := Upper(AllTrim(Left(DTOS((::mAliasInv)->DOC_DATE),4)))
      ::DS:FieldValue("DOC_DATE", value)
      ::TAX_STR:mDate := value //mSetDate(value)
      ::TAX_STR:TAXSTRSUM := value
      if (Upper(alltrim(Left(DTOS(Value),4))) <> OldYear) .And. !(::cWa)->DEF
        //39947
        if !::CheckUniqueNum(.F.)
          ::GetNextNumInv(.F.)
          ::RaiseEvent("TaxInvNumChanged")
        endif
      endif
    //endif
    /*
    if ::DS:REG_DATE > ::DS:DOC_DATE
      ::DS:REG_DATE := ::DS:DOC_DATE
    endif
    */
  ENDIF
RETURN (::mAliasInv)->DOC_DATE

METHOD clsTax_Inv:REG_NUM(value)   // C(06)    Номер документа
  IF (NIL <> value .AND. 0 <> ::EditMode)
    // 39947
    // 2. После выхода с корректировкой из поля
    // "Дата регистрации" программа проверяет рег. номер
    // (номер может быть уже изменен вручную, что не запрещено)
    // на уникальность в пределах года регистрации:
    // ТОЛЬКО если номер не уникален, его меняют!!!
    // Если рег.номер уникален в пределах года его менять не надо - обычный случай ручной правки номера после его первичного формирования.
    //46054
    value := Padr(Alltrim(value),6)
    value := ObrabotkaNom(value,,.T.)
    ::DS:FieldValue("REG_NUM", value)
    ::RaiseEvent("TaxInvNumChanged")
  ENDIF
RETURN (::mAliasInv)->REG_NUM

METHOD clsTax_Inv:REG_DATE(value)  // D        Дата регистрации
local OldYear
  IF (NIL <> value .AND. 0 <> ::EditMode)
    OldYear := Upper(AllTrim(Left(DTOS((::mAliasInv)->REG_DATE),4)))
    ::DS:FieldValue("REG_DATE", value)
    if Upper(alltrim(Left(DTOS(Value),4))) <> OldYear
      if !::CheckUniqueNum(.T.)
        ::GetNextNumInv(.T.)
        ::RaiseEvent("TaxInvNumChanged")
      endif
    endif
  ENDIF
RETURN (::mAliasInv)->REG_DATE
/*
METHOD clsTax_Inv:DEP_DATE(value)  // D        Дата начала амортизации
  IF (NIL <> value .AND. 0 <> ::EditMode)
    if (::mAliasInv)->MOVE_TP == 'КС'
      ::DS:FieldValue("DEP_DATE", value)
    endif
  ENDIF
RETURN (::mAliasInv)->DEP_DATE
*/


METHOD clsTax_Inv:DNUM(value)
  IF (NIL <> value .AND. 0 <> ::EditMode .And. !(::cWa)->DEF )
    ::DS:FieldValue("DNUM", value)
  ENDIF
RETURN (::mAliasInv)->DNUM

METHOD clsTax_Inv:SF_BRG(value)
  IF (NIL <> value .AND. 0 <> ::EditMode .And. !(::cWa)->DEF )
    ::DS:FieldValue("SF_BRG", value)
  ENDIF
RETURN (::mAliasInv)->SF_BRG

METHOD clsTax_Inv:MET_FORM(value)
  IF (NIL <> value .AND. 0 <> ::EditMode)
    ::DS:FieldValue("MET_FORM", value)
  ENDIF
RETURN (::mAliasInv)->MET_FORM

METHOD clsTax_Inv:ENT_ID(value)  // n10 идентификатор фирмы
  IF (NIL <> value .AND. 0 <> ::EditMode)
    ::DS:FieldValue("ENT_ID", value)
  ENDIF
RETURN (::mAliasInv)->ENT_ID

METHOD clsTax_Inv:ENT_LOC(value)  // n10 идентификатор фирмы
  IF (NIL <> value .AND. 0 <> ::EditMode)
    ::DS:FieldValue("ENT_LOC", value)
  ENDIF
RETURN (::mAliasInv)->ENT_LOC

METHOD clsTax_Inv:ENT_LOCNAME()
Return  ::GetAddrName(.T.)

METHOD clsTax_Inv:ENT_CODE()  // C(06)    Код собственного предприятия
local s,cValue
  s := ""
  cValue := ""
  if !Empty((::mAliasInv)->ENT_ID)
    if GetPartnerCodeName((::mAliasInv)->ENT_ID,.T.,@cValue,.T.,"1",::mTbPeople)
      s := cValue
    endif
  endif
RETURN s

METHOD clsTax_Inv:ENT_NAME()
local s,cValue
  s := ""
  cValue := ""
  if !Empty((::mAliasInv)->ENT_ID)
    if GetPartnerCodeName((::mAliasInv)->ENT_ID,.F.,@cValue,.T.,"1",::mTbPeople)
      s := cValue
    endif
  endif
RETURN s

METHOD clsTax_Inv:ENT_ADDRID(value)  // n10 идентификатор фирмы
Local lPol := if((::mAliasInv)->TI_CTG == "1", .T.,.F.)
local cCodeGr := ""
  IF (NIL <> value .AND. 0 <> ::EditMode)
    ::DS:FieldValue("ENT_ADDRID", value)
    (::mAliasInv)->ENT_LOC := GetPartnerAdd(value,lPol)
    if !lPol .And. ::mParamIni[_TAX_USE_DOPNUM] .And. ::mParamIni[_TAX_DNUM_RUL] .And. !::mlIspr
      if !GetPartnerFieldValue(value,"ISOL_CODE",@cCodeGr,.T.,"1",::mTbPeople)
        cCodeGr := ""
      endif
      (::mAliasInv)->DNUM := RTrim(::mParamIni[_TAX_INI_DOPNUM]) + AllTrim(cCodeGr)
    endif
  ENDIF
RETURN (::mAliasInv)->ENT_ADDRID

METHOD clsTax_Inv:ENT_ADDRCODE()  // C(06)    Код собственного предприятия
local s,cValue
  s := ""
  cValue := ""
  if !Empty((::mAliasInv)->ENT_ADDRID)
    if GetPartnerCodeName((::mAliasInv)->ENT_ADDRID,.T.,@cValue,.T.,"1",::mTbPeople)
      s := cValue
    endif
  endif
RETURN s

METHOD clsTax_Inv:ENT_ADDRNAME()
local s,cValue
  s := ""
  cValue := ""
  if !Empty((::mAliasInv)->ENT_ADDRID)
    if GetPartnerCodeName((::mAliasInv)->ENT_ADDRID,.F.,@cValue,.T.,"1",::mTbPeople)
      s := cValue
    endif
  endif
RETURN s

METHOD clsTax_Inv:PRT_TP(value)
  IF (NIL <> value .AND. 0 <> ::EditMode )
    if !(value == "2" .And. (::mAliasInv)->TI_CTG == "1")
    //сотрудник может быть только на продаже
      ::DS:FieldValue("PRT_TP", value)
      if value == "2"
        ::DS:FieldValue("PRT_LOC", "")
        ::DS:FieldValue("PRT_ADDRID", "")
        ::DS:FieldValue("CNT_TYPE", "")
        ::DS:FieldValue("CNT_DOC_ID", "")
        ::DS:FieldValue("ID_OBL","")
      //для сотрудника очищаем поля грузополучатель, основание, тип основания
      endif
    endif
  ENDIF
Return (::mAliasInv)->PRT_TP

METHOD clsTax_Inv:PRT_ID(value)  // C(06)    Код партнера
Local oldPrt := (::mAliasInv)->PRT_ID
Local lRet,cCnt := "",aParam := {}
local sMess := ""
  IF (NIL <> value .AND. 0 <> ::EditMode .And. !::mlRegDoc)
  //altd()
    if !(oldPrt == value)
      ::DS:FieldValue("PRT_ID", value)
      if ::TI_CTG == "1"
        if !::CheckUniqueNum(.F.,@sMess)
          Messagebox(sMess, 'БЭCT-5', 48)
        endif
      endif
      (::mAliasInv)->CNT_DOC_ID := Space(22)
      //И этапы тоже
      (::mAliasInv)->ID_OBL := ''
      //if !_IS_UDAL
        if TakePartnerParamForAP(value,Val((::mAliasInv)->TI_CTG),@aParam,@lRet)
          if lRet
            cCnt := aParam[2]
          endif
        endif
      //endif
      (::mAliasInv)->CNT_TYPE := cCnt
      ::GetAnalit(.T.)
      if (::mAliasInv)->KORR
        ::SFK_ID := ""
      endif
    endif
    //::GetAnalit(.T.)
  ENDIF
RETURN (::mAliasInv)->PRT_ID

METHOD clsTax_Inv:PRT_LOC(value)
  IF (NIL <> value .AND. 0 <> ::EditMode )
    ::DS:FieldValue("PRT_LOC", value)
  ENDIF
RETURN (::mAliasInv)->PRT_LOC

METHOD clsTax_Inv:PARTNER_LOCNAME()
Return  ::GetAddrName(.F.)

METHOD clsTax_Inv:PARTNER_CODE()
local s,cValue
  cValue := ""
  s := ""
  if !Empty((::mAliasInv)->PRT_ID)
    if GetPartnerCodeName((::mAliasInv)->PRT_ID,.T.,@cValue,.F.,(::mAliasInv)->PRT_TP,::mTbPeople)
      s := cValue
    endif
  endif
RETURN s

METHOD clsTax_Inv:PARTNER_NAME()
local s,cValue
  s := ""
  cValue := ""
  if !Empty((::mAliasInv)->PRT_ID)
    if GetPartnerCodeName((::mAliasInv)->PRT_ID,.F.,@cValue,.F.,(::mAliasInv)->PRT_TP,::mTbPeople)
      s := cValue
    endif
  endif
RETURN s

METHOD clsTax_Inv:PRT_ADDRID(value)  // C(06)    Код партнера
Local oldADDRID := (::mAliasInv)->PRT_ADDRID
Local lPol := if((::mAliasInv)->TI_CTG == "1", .F.,.T.)
  IF (NIL <> value .AND. 0 <> ::EditMode)
    if oldADDRID != value
      ::DS:FieldValue("PRT_ADDRID", value)
      (::mAliasInv)->PRT_LOC := GetPartnerAdd(value,lPol)
      //::PRT_LOC := Space(22)
    endif
  ENDIF
RETURN (::mAliasInv)->PRT_ADDRID

METHOD clsTax_Inv:PARTNER_ADDRCODE()
local s,cValue
  s := ""
  cValue := ""
  if !Empty((::mAliasInv)->PRT_ADDRID)
    if GetPartnerCodeName((::mAliasInv)->PRT_ADDRID,.T.,@cValue,.F.,(::mAliasInv)->PRT_TP,::mTbPeople)
      s := cValue
    endif
  endif
RETURN s

METHOD clsTax_Inv:PARTNER_ADDRNAME()
local s,cValue
  s := ""
  cValue := ""
  if !Empty((::mAliasInv)->PRT_ADDRID)
    if GetPartnerCodeName((::mAliasInv)->PRT_ADDRID,.F.,@cValue,.F.,(::mAliasInv)->PRT_TP,::mTbPeople)
      s := cValue
    endif
  endif
RETURN s

METHOD clsTax_Inv:VAL_ID(value)  // N(10)    ID валюты

  IF (NIL <> value .AND. 0 <> ::EditMode .And. !::mlRegDoc)
    ::DS:FieldValue("VAL_ID", value)
    if (DIC_VALUTA)->(DbSeek(value))
      ::mRound := (DIC_VALUTA)->ACCURACY
      ::TAX_STR:mRound := ::mRound
      ::TAX_STR:TAXSTRSUM:mRound := ::mRound

    endif

  ENDIF
RETURN (::mAliasInv)->VAL_ID

METHOD clsTax_Inv:VALMAIN()
RETURN ::mVAL_ID

METHOD clsTax_Inv:VALCODE()  // C(03)    Код валюты
local s
  if (DIC_VALUTA)->(DbSeek((::mAliasInv)->VAL_ID))
    s := (DIC_VALUTA)->CODE
  endif
RETURN s

METHOD clsTax_Inv:VAL_RATE(value)  // N(19,5)  Курс на дату регистрации?
  IF (NIL <> value .AND. 0 <> ::EditMode)
    if value > 0
      if (::mAliasInv)->VAL_ID == ::mVAL_ID
        value := 1
      endif
      ::DS:FieldValue("VAL_RATE", value)
    else
      Messagebox('Значеник курса должно быть больше 0.00 !',TITLEAPP,48)
    endif
  ENDIF
RETURN (::mAliasInv)->VAL_RATE

METHOD clsTax_Inv:SUM_NNDS()  // N(19,4)  Сумма в валюте без НДС

RETURN (::mAliasInv)->SUM_NNDS

METHOD clsTax_Inv:SUM_NDS()   // N(19,4)  Сумма НДС в валюте

RETURN (::mAliasInv)->SUM_NDS

METHOD clsTax_Inv:SUM_A()     // N(19,4)  Сумма в валюте с НДС

RETURN (::mAliasInv)->SUM_A

METHOD clsTax_Inv:SUM_BOOK(value)  // N(19,4)  Сумма по книге в валюте?
  IF (NIL <> value .AND. 0 <> ::EditMode)
    //if (DIC_VALUTA)->(DbSeek((::mAliasInv)->VAL_ID))
      value:=BS_ROUND(value,::mRound/*(DIC_VALUTA)->ACCURACY*/)
    //endif
    ::DS:FieldValue("SUM_BOOK", value)
  ENDIF
RETURN (::mAliasInv)->SUM_BOOK

METHOD clsTax_Inv:SUM_PAY(value)  // N(19,4)
  IF (NIL <> value .AND. 0 <> ::EditMode)
    //if (DIC_VALUTA)->(DbSeek((::mAliasInv)->VAL_ID))
      value:=BS_ROUND(value,::mRound/*(DIC_VALUTA)->ACCURACY*/)
    //endif
    ::DS:FieldValue("SUM_PAY", value)
  ENDIF
RETURN (::mAliasInv)->SUM_PAY

METHOD clsTax_Inv:SUM_SHP(value)  // N(19,4)
  IF (NIL <> value .AND. 0 <> ::EditMode)
    //if (DIC_VALUTA)->(DbSeek((::mAliasInv)->VAL_ID))
      value:=BS_ROUND(value,::mRound/*(DIC_VALUTA)->ACCURACY*/)
    //endif
    ::DS:FieldValue("SUM_SHP", value)
  ENDIF
RETURN (::mAliasInv)->SUM_SHP
/*
METHOD clsTax_Inv:SUM_USE(value)  // N(19,4)
  IF (NIL <> value .AND. 0 <> ::EditMode)
    if (DIC_VALUTA)->(DbSeek((::mAliasInv)->VAL_ID))
      value:=BS_ROUND(value,(DIC_VALUTA)->ACCURACY)
    endif
    ::DS:FieldValue("SUM_USE", value)
  ENDIF
RETURN (::mAliasInv)->SUM_USE
*/
METHOD clsTax_Inv:ST_SUM(value)  // N(19,4)
  IF (NIL <> value .AND. 0 <> ::EditMode)
    //if (DIC_VALUTA)->(DbSeek((::mAliasInv)->VAL_ID))
      value:=BS_ROUND(value,::mRound/*(DIC_VALUTA)->ACCURACY*/)
    //endif
    ::DS:FieldValue("ST_SUM", value)
  ENDIF
RETURN (::mAliasInv)->ST_SUM

METHOD clsTax_Inv:STSUM()
Return (::mAliasInv)->SUM_BOOK - (::mAliasInv)->ST_SUM

METHOD clsTax_Inv:COMMENT_m(value) // M        Комментарий
  IF (NIL <> value .AND. 0 <> ::EditMode)
    ::DS:FieldValue("COMMENT_m", value)
  ENDIF
RETURN (::mAliasInv)->COMMENT_m

METHOD clsTax_Inv:COMPL_m(value)   // M        Дополнение
  IF (NIL <> value .AND. 0 <> ::EditMode)
    ::DS:FieldValue("COMPL_m", value)
  ENDIF
RETURN (::mAliasInv)->COMPL_m

METHOD clsTax_Inv:PAY_COMM(value)   // M        Пладежный документ - текст
  IF (NIL <> value .AND. 0 <> ::EditMode)
    ::DS:FieldValue("PAY_COMM", value)
  ENDIF
RETURN (::mAliasInv)->PAY_COMM

METHOD clsTax_Inv:ACNT_ID(value)      // C(16)    Счет
Local cOldAcnt := Upper((::mAliasInv)->ACNT_ID)
  IF (NIL <> value .AND. ::EditMode<>0 )
    if !(Upper(alltrim( (::mAliasInv)->ACNT_ID )) == Upper(alltrim(value))) .and. CorrectSchet(value)
        ::DS:FieldValue("ACNT_ID",value)
        ::GetAnalit(.T.)
    endif
  ENDIF
RETURN (::mAliasInv)->ACNT_ID

METHOD clsTax_Inv:ACNTNAME()     // Счет
local s,cValue
  s := ""
  cValue := ""
  if !Empty((::mAliasInv)->ACNT_ID)
    if ::GetPSchName((::mAliasInv)->ACNT_ID,@cValue)
      s := cValue
    endif
  endif
RETURN s


METHOD clsTax_Inv:ANALIT(value)    // C(24)    Аналитика
  IF (NIL <> value .AND. 0 <> ::EditMode)
    ::DS:FieldValue("ANALIT", value)
  ENDIF
RETURN (::mAliasInv)->ANALIT
/*
METHOD ISTRANS(value) CLASS clsTax_Inv
   IF value <> NIL .AND. ::EditMode<>0
      ::DS:FieldValue("ISTRANS", value)
   ENDIF
RETURN (::mAliasInv)->ISTRANS
*/
METHOD clsTax_Inv:MOVE_NAME()
local s := ""
  if (::objMOVE_TP)->(DbSeek(Upper((::mAliasInv)->MOVE_TP) ))
    s :=  (::objMOVE_TP)->MOVE_NAME
  endif
RETURN s

METHOD clsTax_Inv:CNT_TYPE(value)
  IF (NIL <> value .AND. 0 <> ::EditMode )
    ::DS:FieldValue("CNT_TYPE", value)
  ENDIF
RETURN (::mAliasInv)->CNT_TYPE

METHOD clsTax_Inv:CNT_DOC_ID(value)
Local cOldCnt := (::mAliasInv)->CNT_DOC_ID
  IF (NIL <> value .AND. 0 <> ::EditMode )
    if !(cOldCnt == value)
      ::DS:FieldValue("CNT_DOC_ID", value)
      ::DS:FieldValue("ID_OBL","")
      ::GetAnalit(.T.)
    endif
  ENDIF
RETURN (::mAliasInv)->CNT_DOC_ID

METHOD clsTax_Inv:ID_OBL(value)
  IF (NIL <> value .AND. 0 <> ::EditMode )
    ::DS:FieldValue("ID_OBL", value)
  ENDIF
RETURN (::mAliasInv)->ID_OBL

METHOD clsTax_Inv:DOCDIM(value)
  IF (NIL <> value .AND. 0 <> ::EditMode )
    ::DS:FieldValue("DOCDIM", value)
  ENDIF
RETURN (::mAliasInv)->DOCDIM

METHOD clsTax_Inv:KORR(value)
  IF (NIL <> value .AND. 0 <> ::EditMode )
    ::DS:FieldValue("KORR", value)
  ENDIF
RETURN (::mAliasInv)->KORR

METHOD clsTax_Inv:SFK_ID(value)
local cKey := "", oldValue := (::mAliasInv)->SFK_ID
local lRet := .F.,RetValue := ""
Local cAlFrom := ""
  IF (NIL <> value .AND. 0 <> ::EditMode .And. !(oldValue == value) )
    // Пропишем значения из корректируемого с-ф
    cKey := value
    ::DelAllStr()
    if ::mCreateFromArc
      cAlFrom := ::GetTaxInvFrom()
    else
      cAlFrom := ::mTbInv
    endif
    if !Empty(cKey)
      (cAlFrom)->(OrdSetFocus("TAG_ID"))
      if (cAlFrom)->(DbSeek(cKey))
        /*  49664 корректировочный для корректировочного
        if (cAlFrom)->KORR
          messagebox("Для корректировочного счет-фактуры корректировочный счет-фактура не создается.",TITLEAPP,48)
          RETURN (::mAliasInv)->SFK_ID
        endif
        */
        (::mAliasInv)->ENT_ID := (cAlFrom)->ENT_ID
        //(::mAliasInv)->ENT_ADDRID := (cAlFrom)->ENT_ADDRID
        ::ENT_ADDRID := (cAlFrom)->ENT_ADDRID
        (::mAliasInv)->PRT_ID := (cAlFrom)->PRT_ID
        (::mAliasInv)->PRT_ADDRID := (cAlFrom)->PRT_ADDRID
        ::VAL_ID := (cAlFrom)->VAL_ID
        ::VAL_RATE := (cAlFrom)->VAL_RATE
        (::mAliasInv)->ACNT_ID := (cAlFrom)->ACNT_ID
        (::mAliasInv)->ANALIT := (cAlFrom)->ANALIT
        (::mAliasInv)->ENT_LOC := (cAlFrom)->ENT_LOC
        (::mAliasInv)->PRT_LOC := (cAlFrom)->PRT_LOC
        (::mAliasInv)->CNT_TYPE := (cAlFrom)->CNT_TYPE
        (::mAliasInv)->CNT_DOC_ID := (cAlFrom)->CNT_DOC_ID
        (::mAliasInv)->PRT_TP := (cAlFrom)->PRT_TP
        (::mAliasInv)->MOD_ID := (cAlFrom)->MOD_ID
        (::mAliasInv)->ID_OBL := (cAlFrom)->ID_OBL
        (::mAliasInv)->KOP_NDS := (cAlFrom)->KOP_NDS
        (::mAliasInv)->KOP_AST := (cAlFrom)->KOP_AST
        (::mAliasInv)->KOP_NNDS := (cAlFrom)->KOP_NNDS
        (::mAliasInv)->KOP_NDS0 := (cAlFrom)->KOP_NDS0
        (::mAliasInv)->KOP_AG_NDS := (cAlFrom)->KOP_AG_NDS
        (::mAliasInv)->PODRAZD := (cAlFrom)->PODRAZD
        (::mAliasInv)->FROM_ARC := ::mCreateFromArc //(::mParamIni[_TAX_DATE_BEG] > (cAlFrom)->REG_DATE)
      else
        RETURN (::mAliasInv)->SFK_ID
      endif
    elseif ValType(value) == "C"
      ::VAL_ID := ""
      ::VAL_RATE := 1
      (::mAliasInv)->ACNT_ID := ""
      (::mAliasInv)->ANALIT := ""
      (::mAliasInv)->MOD_ID := ""
      (::mAliasInv)->KOP_NDS := ""
      (::mAliasInv)->KOP_AST := ""
      (::mAliasInv)->KOP_NNDS := ""
      (::mAliasInv)->KOP_NDS0 := ""
      (::mAliasInv)->KOP_AG_NDS := ""
      (::mAliasInv)->PODRAZD := ""
    endif
    ::mCreateFromArc := .F.
    ::DS:FieldValue("SFK_ID", value)
    ::RaiseEvent("ChangedTaxStr")
  ENDIF
RETURN (::mAliasInv)->SFK_ID

METHOD clsTax_Inv:IS_COMB(value)
  IF (NIL <> value .AND. 0 <> ::EditMode )
    ::DS:FieldValue("IS_COMB", value)
  ENDIF
RETURN (::mAliasInv)->IS_COMB

METHOD clsTax_Inv:DEF(value)
  IF (NIL <> value .AND. 0 <> ::EditMode )
    ::DS:FieldValue("DEF", value)
  ENDIF
RETURN (::mAliasInv)->DEF

METHOD clsTax_Inv:SFMD_ID(value)
local cAlFrom,cKey,oSf,oStr,oCom,oSum
local cAlStCom, cAlStComOld,cAlSf,CSTRID
  IF (NIL <> value .AND. 0 <> ::EditMode )
    ::DS:FieldValue("SFMD_ID", value)
    if ::TAX_STR:EOF() .And. !Empty(value) .And. !::mlKorr .And. !::mlIspr
    //Перенесем значения из выбранного с-ф
      cKey := value
      cAlFrom := ::mTbInv
      (cAlFrom)->(OrdSetFocus("TAG_ID"))

      if (cAlFrom)->(DbSeek(cKey))
        oSf := clsTax_Inv():New()
        oSf:mArc := ::mCreateFromArc
        oSf:Open()
        if !oSf:Seek(cKey,.T.,"TAG_ID")
          RETURN (::mAliasInv)->SFMD_ID
        endif
        cAlSf := oSf:cWa
        //(::mAliasInv)->PRT_ID := (cAlSf)->PRT_ID
        //(::mAliasInv)->PRT_ADDRID := (cAlSf)->PRT_ADDRID
        (::mAliasInv)->ENT_ID := (cAlSf)->PRT_ID
        (::mAliasInv)->ENT_ADDRID := (cAlSf)->PRT_ADDRID
        ::VAL_ID := (cAlSf)->VAL_ID
        ::VAL_RATE := (cAlSf)->VAL_RATE
        (::mAliasInv)->ACNT_ID := (cAlSf)->ACNT_ID
        (::mAliasInv)->ANALIT := (cAlSf)->ANALIT
        //(::mAliasInv)->ENT_LOC := (cAlSf)->ENT_LOC
        //(::mAliasInv)->PRT_LOC := (cAlSf)->PRT_LOC
        (::mAliasInv)->ENT_LOC := (cAlSf)->PRT_LOC
        (::mAliasInv)->CNT_TYPE := (cAlSf)->CNT_TYPE
        (::mAliasInv)->CNT_DOC_ID := (cAlSf)->CNT_DOC_ID
        (::mAliasInv)->PRT_TP := (cAlSf)->PRT_TP
        (::mAliasInv)->MOD_ID := (cAlSf)->MOD_ID
        (::mAliasInv)->ID_OBL := (cAlSf)->ID_OBL
        (::mAliasInv)->KOP_NDS := (cAlSf)->KOP_NDS
        (::mAliasInv)->KOP_AST := (cAlSf)->KOP_AST
        (::mAliasInv)->KOP_NNDS := (cAlSf)->KOP_NNDS
        (::mAliasInv)->KOP_NDS0 := (cAlSf)->KOP_NDS0
        (::mAliasInv)->KOP_AG_NDS := (cAlSf)->KOP_AG_NDS
        (::mAliasInv)->PODRAZD := (cAlSf)->PODRAZD
        (::mAliasInv)->COMMENT_m := (cAlSf)->COMMENT_m
        (::mAliasInv)->COMPL_m := (cAlSf)->COMPL_m
        (::mAliasInv)->DOCDIM := (cAlSf)->DOCDIM
        (::mAliasInv)->PAY_COMM := (cAlSf)->PAY_COMM
        (::mAliasInv)->SFD_ID := (cAlSf)->SFD_ID
        (::mAliasInv)->FROM_ARC := ::mCreateFromArc//(::mParamIni[_TAX_DATE_BEG] > (cAlFrom)->REG_DATE)
        oSf:TAX_STR:GoTop()
        oStr := oSf:TAX_STR

        Do while !oStr:Eof()
          (::mAliasStr)->(DbAppend())
          cStrId                := XGuid()
          (::mAliasStr)->DOC_ID := (::mAliasInv)->DOC_ID
          (::mAliasStr)->STR_ID := cStrId
          (::mAliasStr)->STR_TP := oStr:STR_TP
          (::mAliasStr)->STR_SRC := .F.
          (::mAliasStr)->GROUP_CODE := oStr:GROUP_CODE
          (::mAliasStr)->NNUM := oStr:NNUM
          (::mAliasStr)->UNIT := oStr:UNIT
          (::mAliasStr)->NNAME := oStr:NNAME
          (::mAliasStr)->R := oStr:R
          (::mAliasStr)->QNTY := oStr:QNTY
          (::mAliasStr)->QNTY_BAS := (oStr:cWa)->QNTY_BAS
          (::mAliasStr)->SUM_NDS := oStr:SUM_NDS
          (::mAliasStr)->SUM_A := oStr:SUM_A
          (::mAliasStr)->SUM_NNDS := oStr:SUM_NNDS
          (::mAliasStr)->PRICE := oStr:PRICE
          (::mAliasStr)->CODE := oStr:CODE
          (::mAliasStr)->MDIM := oStr:MDIM
          (::mAliasStr)->GTD := oStr:GTD
          (::mAliasStr)->COUNTRY := oStr:COUNTRY
          (::mAliasStr)->IS_HANDN := oStr:IS_HANDN
          (::mAliasStr)->IS_HANDA := oStr:IS_HANDA
          (::mAliasStr)->NN := (oStr:cWa)->NN
          (::mAliasStr)->PRT_CODE := oStr:PRT_CODE
          ::TAX_STR:Skip(0)
          oCom := oStr:COMMENTM
          oCom:GoTop()
          Do while !oCom:Eof()
            ::TAX_STR:COMMENTM:Append()
            cAlStCom :=  ::TAX_STR:COMMENTM:cWa
            cAlStComOld :=  oCom:cWa
            (cAlStCom)->COMMENT := (cAlStComOld)->COMMENT
            (cAlStCom)->QDOPCHAR1 := (cAlStComOld)->QDOPCHAR1
            (cAlStCom)->QDOPCHAR2 := (cAlStComOld)->QDOPCHAR2
            (cAlStCom)->QDOPCHAR3 := (cAlStComOld)->QDOPCHAR3
            (cAlStCom)->QDOPCHAR4 := (cAlStComOld)->QDOPCHAR4
            (cAlStCom)->QDOPNUM1 := (cAlStComOld)->QDOPNUM1
            (cAlStCom)->QDOPNUM2 := (cAlStComOld)->QDOPNUM2
            (cAlStCom)->QDOPDATA1 := (cAlStComOld)->QDOPDATA1
            (cAlStCom)->QDOPDATA2 := (cAlStComOld)->QDOPDATA2
            (cAlStCom)->KOLFREE := (cAlStComOld)->KOLFREE

            oCom:Skip(1)
          enddo
          oStr:TAXSTRSUM:GoTop()
          oSum := oStr:TAXSTRSUM
          Do while !oSum:Eof()
            (::mAliasSum)->(DbAppend())
            (::mAliasSum)->IDTAXSUM := XGuid()
            (::mAliasSum)->DOC_ID :=  (::mAliasInv)->DOC_ID
            (::mAliasSum)->STR_ID := cStrId
            (::mAliasSum)->TAX_ID := oSum:TAX_ID
            (::mAliasSum)->TAX_IDRT := oSum:TAX_IDRT
            (::mAliasSum)->PRIOR := oSum:PRIOR
            (::mAliasSum)->TAX_RATE := oSum:TAX_RATE
            (::mAliasSum)->TAX_BASE := oSum:TAX_BASE
            (::mAliasSum)->TAX_SUM := oSum:TAX_SUM
            (::mAliasSum)->IS_HAND := oSum:IS_HAND
            oSum:Skip(1)
          enddo
          //endif
          oStr:Skip(1)
       enddo
       if (::mAliasInv)->TI_CTG == "2"
         ::GetNextNumInv(.F.)
       endif
       ::CreateTaxForSF()
       ::TAX_STR:GoTop()
       oSf:Destroy()
       oSf := nil
      else
        RETURN (::mAliasInv)->SFMD_ID
      endif
    ::RaiseEvent("ChangedTaxStr")
    endif
    ::DS:FieldValue("MD_ID", "")
  ENDIF
RETURN (::mAliasInv)->SFMD_ID

METHOD clsTax_Inv:MD_ID(value)
  IF (NIL <> value .AND. 0 <> ::EditMode )
    ::DS:FieldValue("MD_ID", value)
    ::DS:FieldValue("SFMD_ID", "")
  ENDIF
RETURN (::mAliasInv)->MD_ID

METHOD clsTax_Inv:SFD_ID(value)
local cKey := "", oldValue := (::mAliasInv)->SFD_ID
local oSf,cAlSf,oStr,cStrId,oSum,oCom,cAlStCom,cAlStComOld
local aStr := {},i,cAlFrom := ""
  IF (NIL <> value .AND. 0 <> ::EditMode .And. !(oldValue == value) )
    // Пропишем значения из корректируемого с-ф
    ::DelAllStr()
    ::aStrS := {}
    cKey := value
    if !Empty(cKey)
      if ::mCreateFromArc
        cAlFrom := ::GetTaxInvFrom()
      else
        cAlFrom := ::mTbInv
      endif
      (cAlFrom)->(OrdSetFocus("TAG_ID"))

      if (cAlFrom)->(DbSeek(cKey))
        oSf := clsTax_Inv():New()
        oSf:mArc := ::mCreateFromArc
        oSf:Open()
        if !oSf:Seek(cKey,.T.,"TAG_ID")
          RETURN (::mAliasInv)->SFD_ID
        endif
        cAlSf := oSf:cWa
        //(::mAliasInv)->DOC_DATE := (cAlSf)->DOC_DATE
        (::mAliasInv)->ENT_ID := (cAlSf)->ENT_ID
        (::mAliasInv)->ENT_ADDRID := (cAlSf)->ENT_ADDRID
        (::mAliasInv)->PRT_ID := (cAlSf)->PRT_ID
        (::mAliasInv)->PRT_ADDRID := (cAlSf)->PRT_ADDRID
        ::VAL_ID := (cAlSf)->VAL_ID
        ::VAL_RATE := (cAlSf)->VAL_RATE
        (::mAliasInv)->ACNT_ID := (cAlSf)->ACNT_ID
        (::mAliasInv)->ANALIT := (cAlSf)->ANALIT
        (::mAliasInv)->ENT_LOC := (cAlSf)->ENT_LOC
        (::mAliasInv)->PRT_LOC := (cAlSf)->PRT_LOC
        (::mAliasInv)->CNT_TYPE := (cAlSf)->CNT_TYPE
        (::mAliasInv)->CNT_DOC_ID := (cAlSf)->CNT_DOC_ID
        (::mAliasInv)->PRT_TP := (cAlSf)->PRT_TP
        (::mAliasInv)->MOD_ID := (cAlSf)->MOD_ID
        (::mAliasInv)->ID_OBL := (cAlSf)->ID_OBL
        (::mAliasInv)->KOP_NDS := (cAlSf)->KOP_NDS
        (::mAliasInv)->KOP_AST := (cAlSf)->KOP_AST
        (::mAliasInv)->KOP_NNDS := (cAlSf)->KOP_NNDS
        (::mAliasInv)->KOP_NDS0 := (cAlSf)->KOP_NDS0
        (::mAliasInv)->KOP_AG_NDS := (cAlSf)->KOP_AG_NDS
        (::mAliasInv)->PODRAZD := (cAlSf)->PODRAZD
        (::mAliasInv)->COMMENT_m := (cAlSf)->COMMENT_m
        (::mAliasInv)->COMPL_m := (cAlSf)->COMPL_m
        (::mAliasInv)->DOCDIM := (cAlSf)->DOCDIM
        (::mAliasInv)->PAY_COMM := (cAlSf)->PAY_COMM
        (::mAliasInv)->SFD_ID := (cAlSf)->DOC_ID
        (::mAliasInv)->FROM_ARC := ::mCreateFromArc//(::mParamIni[_TAX_DATE_BEG] > (cAlFrom)->REG_DATE)
        ::mOldKorr := (cAlSf)->SFK_ID
        oSf:TAX_STR:GoTop()
        oStr := oSf:TAX_STR

        Do while !oStr:Eof()
            if (cAlSf)->KORR
              if Empty((oStr:cWa)->STR_V)
                 AADD(::aStrS,{(oStr:cWa)->STRS_ID,.F.})
              endif
            endif
            (::mAliasStr)->(DbAppend())
            cStrId                := XGuid()
            if (cAlSf)->KORR .And. Empty((oStr:cWa)->STR_V)
              AADD(aStr,{(oStr:cWa)->STR_ID,cStrId})
            endif
            (::mAliasStr)->DOC_ID := (::mAliasInv)->DOC_ID
            (::mAliasStr)->STR_ID := cStrId
            (::mAliasStr)->STR_TP := oStr:STR_TP
            (::mAliasStr)->STR_SRC := .F. //oStr:STR_SRC
            (::mAliasStr)->GROUP_CODE := oStr:GROUP_CODE
            (::mAliasStr)->NNUM := oStr:NNUM
            (::mAliasStr)->UNIT := oStr:UNIT
            (::mAliasStr)->NNAME := oStr:NNAME
            (::mAliasStr)->R := oStr:R
            (::mAliasStr)->QNTY := oStr:QNTY
            (::mAliasStr)->QNTY_BAS := (oStr:cWa)->QNTY_BAS
            (::mAliasStr)->SUM_NDS := oStr:SUM_NDS
            (::mAliasStr)->SUM_A := oStr:SUM_A
            (::mAliasStr)->SUM_NNDS := oStr:SUM_NNDS
            (::mAliasStr)->PRICE := oStr:PRICE
            (::mAliasStr)->CODE := oStr:CODE
            (::mAliasStr)->MDIM := oStr:MDIM
            (::mAliasStr)->GTD := oStr:GTD
            (::mAliasStr)->COUNTRY := oStr:COUNTRY
            (::mAliasStr)->IS_HANDN := oStr:IS_HANDN
            (::mAliasStr)->IS_HANDA := oStr:IS_HANDA
            (::mAliasStr)->NN := (oStr:cWa)->NN
            (::mAliasStr)->PRT_CODE := oStr:PRT_CODE
            if (cAlSf)->KORR
              (::mAliasStr)->STR_V := (oStr:cWa)->STR_V
              (::mAliasStr)->STRS_ID := (oStr:cWa)->STRS_ID
              (::mAliasStr)->STRN_ID := (oStr:cWa)->STRN_ID
            endif
            ::TAX_STR:Skip(0)
            oCom := oStr:COMMENTM
            oCom:GoTop()
            Do while !oCom:Eof()
              ::TAX_STR:COMMENTM:Append()
              cAlStCom :=  ::TAX_STR:COMMENTM:cWa
              cAlStComOld :=  oCom:cWa
              (cAlStCom)->COMMENT := (cAlStComOld)->COMMENT
              (cAlStCom)->QDOPCHAR1 := (cAlStComOld)->QDOPCHAR1
              (cAlStCom)->QDOPCHAR2 := (cAlStComOld)->QDOPCHAR2
              (cAlStCom)->QDOPCHAR3 := (cAlStComOld)->QDOPCHAR3
              (cAlStCom)->QDOPCHAR4 := (cAlStComOld)->QDOPCHAR4
              (cAlStCom)->QDOPNUM1 := (cAlStComOld)->QDOPNUM1
              (cAlStCom)->QDOPNUM2 := (cAlStComOld)->QDOPNUM2
              (cAlStCom)->QDOPDATA1 := (cAlStComOld)->QDOPDATA1
              (cAlStCom)->QDOPDATA2 := (cAlStComOld)->QDOPDATA2
              (cAlStCom)->KOLFREE := (cAlStComOld)->KOLFREE

              oCom:Skip(1)
            enddo
            oStr:TAXSTRSUM:GoTop()
            oSum := oStr:TAXSTRSUM
            Do while !oSum:Eof()
              (::mAliasSum)->(DbAppend())
              (::mAliasSum)->IDTAXSUM := XGuid()
              (::mAliasSum)->DOC_ID :=  (::mAliasInv)->DOC_ID
              (::mAliasSum)->STR_ID := cStrId
              (::mAliasSum)->TAX_ID := oSum:TAX_ID
              (::mAliasSum)->TAX_IDRT := oSum:TAX_IDRT
              (::mAliasSum)->PRIOR := oSum:PRIOR
              (::mAliasSum)->TAX_RATE := oSum:TAX_RATE
              (::mAliasSum)->TAX_BASE := oSum:TAX_BASE
              (::mAliasSum)->TAX_SUM := oSum:TAX_SUM
              (::mAliasSum)->IS_HAND := oSum:IS_HAND
              oSum:Skip(1)
            enddo
          //endif
          oStr:Skip(1)
        enddo
        if (::mAliasInv)->TI_CTG == "2"
          ::GetNextNumInv(.F.)
        endif
        ::CreateTaxForSF()
        ::TAX_STR:GoTop()
        do while !::TAX_STR:Eof()
          if (::mAliasStr)->STR_V == "P"
            for i := 1 to len(aStr)
              if (::mAliasStr)->STRN_ID == aStr[i][1]
                (::mAliasStr)->STRN_ID := aStr[i][2]
                exit
              endif
            next
          endif
          ::TAX_STR:Skip(1)
        enddo
        oSf:Destroy()
        oSf := nil
      else
        RETURN (::mAliasInv)->SFD_ID
      endif
    elseif ValType(value) == "C"
      ::VAL_ID := ""
      ::VAL_RATE := 1
      (::mAliasInv)->ACNT_ID := ""
      (::mAliasInv)->ANALIT := ""
      (::mAliasInv)->MOD_ID := ""
      (::mAliasInv)->KOP_NDS := ""
      (::mAliasInv)->KOP_AST := ""
      (::mAliasInv)->KOP_NNDS := ""
      (::mAliasInv)->KOP_NDS0 := ""
      (::mAliasInv)->KOP_AG_NDS := ""
      (::mAliasInv)->PODRAZD := ""
    endif
    ::mCreateFromArc := .F.
    ::DS:FieldValue("SFD_ID", value)
    ::RaiseEvent("ChangedTaxStr")
  ENDIF
RETURN (::mAliasInv)->SFD_ID

METHOD clsTax_Inv:CNTVID()
RETURN ::GetBrg(1)

METHOD clsTax_Inv:CNTNUM()
RETURN ::GetBrg(2)

METHOD clsTax_Inv:CNTDATE()
RETURN ::GetBrg(3)

METHOD clsTax_Inv:CNTDOCDIM()
RETURN ::GetBrg(5)

METHOD clsTax_Inv:SFANALIT()
local s := "",cAlg := ""
  if !((::mAliasInv)->(EOF()) .Or. (::mAliasInv)->(BOF()))
    if (DIC_Dim_anl)->(DbSeek("0000000000000000001042"))
      cAlg := Alltrim((DIC_Dim_anl)->ALG_CODE)
      s := (::mAliasInv)->(&cAlg)
    endif
  endif
Return s

METHOD clsTax_Inv:CNTANALIT()
RETURN ::GetBrg(4)

METHOD clsTax_Inv:IS_FULL(value)
   IF value <> NIL .AND. ::EditMode<>0
      ::DS:FieldValue("IS_FULL", value)
   ENDIF
RETURN (::mAliasInv)->IS_FULL

METHOD clsTax_Inv:IS_ANUL()
RETURN (::mAliasInv)->IS_ANUL

METHOD clsTax_Inv:STR_TP2(value) //L(1)
   IF value <> NIL .AND. ::EditMode<>0
      ::DS:FieldValue("STR_TP2", value)
   ENDIF
RETURN (::mAliasInv)->STR_TP2

METHOD clsTax_Inv:SHP_TP2(value) //L(1)
   IF value <> NIL .AND. ::EditMode<>0
      ::DS:FieldValue("SHP_TP2", value)
   ENDIF
RETURN (::mAliasInv)->SHP_TP2

METHOD clsTax_Inv:STR_TP3(value) //L(1)
   IF value <> NIL .AND. ::EditMode<>0
      ::DS:FieldValue("STR_TP3", value)
   ENDIF
RETURN (::mAliasInv)->STR_TP3

METHOD clsTax_Inv:SHP_TP3(value) //L(1)
   IF value <> NIL .AND. ::EditMode<>0
      ::DS:FieldValue("SHP_TP3", value)
   ENDIF
RETURN (::mAliasInv)->SHP_TP3

METHOD clsTax_Inv:STR_TP4(value) //L(1)
   IF value <> NIL .AND. ::EditMode<>0
      ::DS:FieldValue("STR_TP4", value)
   ENDIF
RETURN (::mAliasInv)->STR_TP4

METHOD clsTax_Inv:SHP_TP4(value) //L(1)
   IF value <> NIL .AND. ::EditMode<>0
      ::DS:FieldValue("SHP_TP4", value)
   ENDIF
RETURN (::mAliasInv)->SHP_TP4

METHOD clsTax_Inv:STR_TP5(value) //L(1)
   IF value <> NIL .AND. ::EditMode<>0
      ::DS:FieldValue("STR_TP5", value)
   ENDIF
RETURN (::mAliasInv)->STR_TP5

METHOD clsTax_Inv:SHP_TP5(value) //L(1)
   IF value <> NIL .AND. ::EditMode<>0
      ::DS:FieldValue("SHP_TP5", value)
   ENDIF
RETURN (::mAliasInv)->SHP_TP5

METHOD clsTax_Inv:MOD_ID(value)  //C(22)
   IF value <> NIL .AND. ::EditMode<>0
      ::DS:FieldValue("MOD_ID", value)
   ENDIF
RETURN (::mAliasInv)->MOD_ID

METHOD clsTax_Inv:AnalitName()
  if !empty((::mAliasInv)->ANALIT)
    return ParseAnalitCode((::mAliasInv)->ACNT_ID,(::mAliasInv)->ANALIT, , .T.)
  endif
RETURN ""

METHOD clsTax_Inv:KOP_NDS(value)  //C(7)
   IF value <> NIL .AND. ::EditMode<>0
      ::DS:FieldValue("KOP_NDS", value)
   ENDIF
RETURN (::mAliasInv)->KOP_NDS

METHOD clsTax_Inv:KOP_AST(value)  //C(7)
   IF value <> NIL .AND. ::EditMode<>0
      ::DS:FieldValue("KOP_AST", value)
   ENDIF
RETURN (::mAliasInv)->KOP_AST

METHOD clsTax_Inv:KOP_NNDS(value)  //C(7)
   IF value <> NIL .AND. ::EditMode<>0
      ::DS:FieldValue("KOP_NNDS", value)
   ENDIF
RETURN (::mAliasInv)->KOP_NNDS

METHOD clsTax_Inv:KOP_NDS0(value)  //C(7)
   IF value <> NIL .AND. ::EditMode<>0
      ::DS:FieldValue("KOP_NDS0", value)
   ENDIF
RETURN (::mAliasInv)->KOP_NDS0

METHOD clsTax_Inv:KOP_AG_NDS(value)  //C(7)
   IF value <> NIL .AND. ::EditMode<>0
      ::DS:FieldValue("KOP_AG_NDS", value)
   ENDIF
RETURN (::mAliasInv)->KOP_AG_NDS

METHOD clsTax_Inv:KOPNDSNAME()  //C(50)
local s := "",cKey := (::cWa)->KOP_NDS
  if !Empty(cKey)
    cKey :=Upper('0000000000000000001068' + cKey)
    if (::mAnlSeg)->(DbSeek(cKey))
      s := (::mAnlSeg)->NAME
    endif
  endif
RETURN s

METHOD clsTax_Inv:KOPASTNAME()  //C(50)
local s := "",cKey := (::cWa)->KOP_AST
  if !Empty(cKey)
    cKey :=Upper('0000000000000000001077' + cKey)
    if (::mAnlSeg)->(DbSeek(cKey))
      s := (::mAnlSeg)->NAME
    endif
  endif
RETURN s

METHOD clsTax_Inv:KOPNNDSNAME()  //C(50)
local s := "",cKey := (::cWa)->KOP_NNDS
  if !Empty(cKey)
    cKey :=Upper('0000000000000000001060' + cKey)
    if (::mAnlSeg)->(DbSeek(cKey))
      s := (::mAnlSeg)->NAME
    endif
  endif
RETURN s

METHOD clsTax_Inv:KOPNDS0NAME()  //C(50)
local s := "",cKey := (::cWa)->KOP_NDS0
  if !Empty(cKey)
    cKey :=Upper('0000000000000000001048' + cKey)
    if (::mAnlSeg)->(DbSeek(cKey))
      s := (::mAnlSeg)->NAME
    endif
  endif
RETURN s

METHOD clsTax_Inv:KOPAGNDSNAME()  //C(50)
local s := "",cKey := (::cWa)->KOP_AG_NDS
  if !Empty(cKey)
    cKey :=Upper('0000000000000000001061' + cKey)
    if (::mAnlSeg)->(DbSeek(cKey))
      s := (::mAnlSeg)->NAME
    endif
  endif
RETURN s

METHOD clsTax_Inv:PODRAZD(value)  //C(7)
   IF value <> NIL .AND. ::EditMode<>0
      ::DS:FieldValue("PODRAZD", value)
   ENDIF
RETURN (::mAliasInv)->PODRAZD

METHOD clsTax_Inv:FROM_ARC(value)
  IF (NIL <> value .AND. 0 <> ::EditMode)
    ::DS:FieldValue("FROM_ARC", value)
  ENDIF
RETURN (::mAliasInv)->FROM_ARC


///////////////////////////
// PG
// Создание рекордсета на справочник партнеров при открытии С-Ф
// код возврата - успешно Т иначе F
/////////////////////////
METHOD clsTax_Inv:Open()
local lRet
//altd()
  lRet := .F.
  if ValType(::ParentBo) == "O" .And. Upper(AllTrim(::ParentBo:ClassName)) == Upper("clsTax_Book")
    ::mArc := ::ParentBo:mArc
  endif
  if ::mArc
    lRet := ::clsMetaBO:Open("Tax\Arc\TAX_INV.dbf", "TAG_ID")
  else
    lRet := ::clsMetaBO:Open("Tax\TAX_INV.dbf", "TAG_ID")
  endif
  if lRet
    ::mAliasInv := ::DS:Alias()
    ::mAliasStr := ::TAX_STR:DS:Alias()
    ::mAliasSum := ::TAX_STR:TAXSTRSUM:DS:Alias()
    if ::mArc
      if ! _DbAreaOpen(B6_DBF_PATH + "Tax\Arc\TAX_INV.dbf", @::mTbInv,"TAG_ID")
        RETURN .F.
      endif
    else
      if ! _DbAreaOpen(B6_DBF_PATH + "Tax\Tax_Inv.dbf", @::mTbInv,"TAG_ID")
        RETURN .F.
      endif
    endif
    if ! _DbAreaOpen(B6_DBF_PATH + "PEOPLE.DBF", @::mTbPeople,"TAG_IDP")
      RETURN .F.
    endif
    if ! _DbAreaOpen(B6_DBF_PATH + "Tax\MOVE_TP.dbf", @::ObjMOVE_TP,"Tag_TP")
      RETURN .F.
    endif
    if ! _DbAreaOpen(B6_DBF_PATH + "Doc_Type.dbf", @::ObjDOC_TYPE,"TAG_ID")
      RETURN .F.
    endif
    if ! _DbAreaOpen(B6_DBF_PATH + "analit_seg.dbf", @::mAnlSeg,"CODE")
      RETURN .F.
    endif
    if ! _DbAreaOpen(B6_DBF_PATH + "Tax\TAX_STR_TP.DBF", @::STPTP,"TAG_TP")
      RETURN .F.
    endif

  endif

RETURN  lRet

Method  clsTax_Inv:Destroy()
Local i
  //if ValType(::TAX_STR)== "O"
  //  ::TAX_STR:RemoveEvent("ChangedStr")
  //endif
  //if ValType(::objModStr) == "O"
  //  ::objModStr:Destroy()
  //  ::objModStr := nil
  //endif

  if ValType(::mTbPartAddr) == "O"
    ::mTbPartAddr:Destroy()
    ::mTbPartAddr := nil
  endif

  if ValType(::maTbDoc) == "A"
    for i := 1 to len(::maTbDoc)

    /*if ValType(::maTbDoc[i][2]) == "O"
      ::maTbDoc[i][2]:Destroy()
    endif */
      _DbAreaClose(::maTbDoc[i][2])
      _DbAreaClose(::maTbDoc[i][5])
    next
    ::maTbDoc := nil
  endif

  if ValType(::aTabCnt) == "A"
    for i := 1 to len(::aTabCnt)
      if ValType(::aTabCnt[i][2]) == "O"
        ::aTabCnt[i][2]:Destroy()
      endif
    next
    ::aTabCnt := nil
  endif

  if ValType(::mTbCard) == "O"
    ::mTbCard:Destroy()
    ::mTbCard := nil
  endif
  if ValType(::mTbApReg) == "O"
    ::mTbApReg:Destroy()
    ::mTbApReg := nil
  endif
  /*
  for i := 1 to len(::maTbStr)
    _DbAreaClose(::maTbStr[i])
  next
  */
  //_DbAreaClose(::mTbPSch)
  _DbAreaCloseA({::mTbSeg,;
                 ::mAliasTaxTp,;
                 ::mTbPeople,;
                 ::mAnlSeg,;
                 ::ObjMOVE_TP,;
                 ::ObjDOC_TYPE,;
                 ::mTbInv,;
                 ::mTbInvArc,;
                 ::STPTP})

  ::ClsMetaBO:Destroy()
Return .T.
//////////////////////
// PG
// Удаление отметок в связанных документа после удаления С-Ф
// и разблокирование этих документов
////////////////////

METHOD clsTax_Inv:edit(x)
Local lRet := .F.
  if ::CanEdit := CanEdit('16', .f.)
    ::CanEdit := CanActionMoveTpForTax(self,.T.,_EDIT_)
  endif
  if  !::clsMetaBO:edit(x)
    ::mlHandSum := .F.
  else
    ::mlHandSum := .T.
    lRet := .T.
  endif
return lRet
// lAll - Если Т - удаляем все записи
METHOD clsTax_Inv:Delete(lAll)
Local i,lRet := .T.  ,lRetAr := .T.
Local oObjBook,cMsg ,r
Local nRec,oBook,lUn := .F.,lSt := .F. ,a := {}
local aUn := {} , cAlBook, cAlBkTax,cAlias,cAliasDop,cKey
   if ValType(lAll) != "L"
     lAll := .F.
   endif

   if !CanDelete('16', .t.)
     return .f.
   else
     if !CanActionMoveTpForTax(self,.T.,_DELETE_)
       RightMessage()
       return .f.
     endif
   endif

   lRetAr := .F.
   if !LookUpSeek("TAX\ARC\TAX_INV.Dbf","TAG_ID",@lRetAr,(::cWa)->DOC_ID )
     return .f.
   endif
   if lRetAr
     messagebox("Счет-фактура в закрытом периоде.",TITLEAPP,48)
     return .f.
   endif
   lRet := .T.
   if !::BOOK:EOF() .Or. !::BOOKST:EOF()
    //Проверим есть или нет анулированные записи
     oBook := ::BOOK:DS
     nRec := oBook:RecNo()
     oBook:GoTop()
     Do while !oBook:Eof()
       if oBook:CMP_TP $ "1,3"
         lUn := .T.
         if lAll
           AADD(aUn,oBook:RecNo())
         else
           exit
         endif
       endif
       //Проверим нет ли авансового с-ф в архивном периоде
       if (::cWa)->FROM_ARC .And. (!Empty((::cWa)->SFD_ID) .Or. !Empty((::cWa)->SFK_ID) )
       else
         lRetAr := .F.
         if !LookUpSeek("TAX\ARC\BOOK.Dbf","TAG_ID",@lRetAr,oBook:BOOK_ID )
           oBook:GoTo(nRec)
           Return .F.
         endif
         if lRetAr
           messagebox("Запись в книгу в закрытом периоде.",TITLEAPP,48)
           oBook:GoTo(nRec)
           Return .F.
         endif
       endif
       if !(oBook:CMP_TP $ "1,3")
         AADD(a,{oBook:RecNo(),oBook:BOOK_ID})
       endif
       oBook:Skip(1)
     enddo
     if lUn .And. !lAll
       messagebox("По счету-фактуре есть аннулированные записи в книге.",TITLEAPP,48)
       oBook:GoTo(nRec)
       Return .F.
     endif
     oBook:GoTo(nRec)

     oBook := ::BOOKST:DS
     nRec := oBook:RecNo()
     oBook:GoTop()
     Do while !oBook:Eof()
       lSt := .T.
       if oBook:CMP_TP $ "1,3"
         lUn := .T.
         if lAll
           AADD(aUn,oBook:RecNo())
         else
           exit
         endif
       endif
       //Проверим нет ли авансового с-ф в архивном периоде
       if (::cWa)->FROM_ARC .And. (!Empty((::cWa)->SFD_ID) .Or. !Empty((::cWa)->SFK_ID) )
       else
         lRetAr := .F.
         if !LookUpSeek("TAX\ARC\BOOK.Dbf","TAG_ID",@lRetAr,oBook:BOOK_ID )
           oBook:GoTo(nRec)
           Return .F.
         endif
         if lRetAr
           messagebox("Запись в книгу в закрытом периоде.",TITLEAPP,48)
           oBook:GoTo(nRec)
           Return .F.
         endif
       endif

       if !(oBook:CMP_TP $ "1,3")
         AADD(a,{oBook:RecNo(),oBook:BOOK_ID})
       endif
       oBook:Skip(1)
     enddo
     if lUn .And. !lAll
       messagebox("По счету-фактуре есть аннулированные записи в книге.",TITLEAPP,48)
       oBook:GoTo(nRec)
       Return .F.
     endif
     oBook:GoTo(nRec)
     if lSt
       cMsg := "По счету-фактуре есть сторнирующие записи в книге." + CRLF
     else
       cMsg := "По счету-фактуре есть регистрационные записи в книге." + CRLF
     endif
     cMsg += "Вместе со счетом-фактурой будут удалены записи в книге." + CRLF
     cMsg += "Удалить счет-фактуру?"
     if ::lMsgDelBook
       r :=messagebox(cMsg,TITLEAPP,36)
       if !(r == 6)
         Return .F.
       endif
     else
       ::lMsgDelBook := .T.
     endif

     begin sequence

     trans_begin()

       oObjBook := clsTax_Book():New()
       if (::cWa)->MOVE_TP $ {'ПР','ПП'}
         oObjBook:lSfStDel := .T.
       else
         oObjBook:lSfDel := .T.
       endif
       oObjBook:Open()
       oObjBook:lDelDocs := .F.
       for i := 1 to len(a)
         oObjBook:GoTo(a[i][1])
         if !oObjBook:Delete()
           Break nil
         endif
       next

       for i := 1 to len(aUn)
         oObjBook:GoTo(aUn[i])
         cAlBook := oObjBook:cWa
         cAlBkTax := oObjBook:BKTAX:cWa
         (cAlBkTax)->(DbGoTop())
         Do While !(cAlBkTax)->(Eof())
           if (cAlBkTax)->(DbRLock((cAlBkTax)->(RecNo())))
             (cAlBkTax)->(DbDelete())
             (cAlBkTax)->(DbRUnLock((cAlBkTax)->(RecNo())))
           endif
           (cAlBkTax)->(DbSkip(1))
         enddo
         if (cAlBook)->(DbRLock((cAlBook)->(RecNo())))
             (cAlBook)->(DbDelete())
             (cAlBook)->(DbRUnLock((cAlBook)->(RecNo())))
           endif
       next
       /*
       if !::BOOK:EOF()
         oObjBook:lSfDel := .T.
         oObjBook:DS:SetOrder("TAG_SF")
         oObjBook:DS:Scope((::MAliasInv)->Doc_Id ,(::MAliasInv)->Doc_Id, "TAG_SF")
         oObjBook:DS:GoTop()
         Do While !oObjBook:Eof()
           if !oObjBook:Delete()
             oObjBook:Skip(1)
           endif
         enddo
       endif
       if !::BOOKST:EOF()
         oObjBook:lSfDel := .F.
         oObjBook:DS:SetOrder("TAG_SFST")
         oObjBook:DS:Scope((::MAliasInv)->Doc_Id ,(::MAliasInv)->Doc_Id, "TAG_SFST")
         oObjBook:DS:GoTop()
         Do While !oObjBook:Eof()
           if !oObjBook:Delete()
             oObjBook:Skip(1)
           endif
         enddo
       endif
      */

     trans_commit()
     for i := 1 to len(a)
       DelAllDocs(a[i][2])
     next

    recover

      trans_rollback()
      lRet := .F.
     end sequence
     if ValType(oObjBook) == "O"
       oObjBook:Destroy()
       oObjBook := nil
     endif
   endif

   if !lRet
     Return .F.
   endif

  begin sequence
  trans_begin()

  if !Empty((::cWa)->SFK_ID)
    if ! _DbAreaOpen(B6_DBF_PATH + "Tax\TAX_STR.dbf", @cAlias,"TAG_ID")
      Break
    endif
    if ! _DbAreaOpen(B6_DBF_PATH + "Tax\ARC\TAX_STR.dbf", @cAliasDop,"TAG_ID")
      Break
    endif

    ::Tax_Str:GoTop()
    Do While !(::mAliasStr)->(Eof())
      cKey := (::mAliasStr)->STRS_ID
      if !Empty(cKey) .And. Empty((::mAliasStr)->STR_V)
        if (cAlias)->(DbSeek(cKey))
          if (cAlias)->(DbRLock((cAlias)->(RecNo())))
            (cAlias)->STR_V := " "
            (cAlias)->(DbRUnLock((cAlias)->(RecNo())))
          endif
        endif
        if (cAliasDop)->(DbSeek(cKey))
          if (cAliasDop)->(DbRLock((cAliasDop)->(RecNo())))
            (cAliasDop)->STR_V := " "
            (cAliasDop)->(DbRUnLock((cAliasDop)->(RecNo())))
          endif
        endif
      endif
      (::mAliasStr)->(DbSkip(1))
    enddo
  endif
  if !::clsMetaBO:Delete()
     ::Tax_Str:mDocDelete := .F.
     Break
  endif

  trans_commit()

 recover
   trans_rollback()
   lRet := .F.
 end sequence
 _DbAreaClose(cAlias)
 _DbAreaClose(cAliasDop)
 for i := 1 to len(::maTbDoc)
   _DbAreaClose(::maTbDoc[i][2])
   _DbAreaClose(::maTbDoc[i][5])
 next
 ::maTbDoc := {}
 ::aSFDOC := {}

Return lRet
////////////////////
//PG
// Разблокировка связанных документов
// Регистрация для групповых записей в Книгк П/П
// и регистрация д-тов на основании которых создан Счет-Фактура
// Создание для платежей авансовых записей в Книге П/П
// Создание сторнирующих записей
METHOD clsTax_Inv:Save()
local n,i,lRet := .F.,cPay := "0"//a,
local cAlias,nReReg := 0,s,s1,oObjBook,aBook
Local cDocId,cIdOper,cJrn , lNewBook := .T.
local nRate , aRight := {}
  ::maTran := {}
  if !Empty((::cWa)->SFK_ID)
    if Select(::TAX_STR:mAliasStrS) < 1
      if !::TAX_STR:OpenS()
        RETURN .F.
      endif
    endif
    (::TAX_STR:mAliasStrS)->(WaEdit())
    AADD(::maTran,::TAX_STR:mAliasStrS)
    if (::cWa)->From_Arc
      if ! _DbAreaOpen(B6_DBF_PATH + "TAX\TAX_STR.dbf", @::mAliasSin,"TAG_ID")
        RETURN .F.
      endif
      (::mAliasSin)->(WaEdit())
      AADD(::maTran,::mAliasSin)
    endif

  endif
  if ::mReMakeBook
  // Проверим регистрацию по документу
    if len(::maReRegDoc)>0
      cAlias := ::Book:Ds:alias()
      (cAlias)->(DbGoTop())
      cDocId := ::maReRegDoc[1]
      Do While !(cAlias)->(Eof())
        if (cAlias)->Src_id == cDocId
          if ValType(::maReRegDoc[2]) == "N"
            nRate := iif(Empty((cAlias)->SRC_RATE),1,(cAlias)->SRC_RATE)
            if !(BS_ROUND((cAlias)->REC_SUM,::mRound) == BS_ROUND(::maReRegDoc[2]*nRate,::mRound))
              s := "Регистрационная запись по "
              cJrn := (cAlias)->JRN_ID
              if cJrn $ "0301,0901,0904"
                s := s + "накладной "
              else
                s := s + "акту "
              endif
              s := s + chr(13) + chr(10)
              s := s + ::maReRegDoc[3] + chr(13) + chr(10)
              s := s + "сформирована неверно."
              s1 := "'Переформировать' 1 Default 'Удалить' 2 'Вернуться в счет-фактуру' 3"
              nReReg := D_CUSTOMMSG("БЭСТ-5", s, s1, 3, .t.)
              if nReReg == 3
                Return .F.
              endif
            endif
          else
            s := "Регистрационная запись по "
            cJrn := (cAlias)->JRN_ID
            if cJrn $ "0301,0901,0904"
              s := s + "накладной "
            else
              s := s + "акту "
            endif
            s := s + chr(13) + chr(10)
            s := s + "сформирована по удаляемому документу."
              s1 := "'Удалить' 1 Default 'Вернуться в счет-фактуру' 2"
              nReReg := D_CUSTOMMSG("БЭСТ-5", s, s1, 3, .t.)
              if nReReg == 2
                Return .F.
              else
                nReReg := 2
              endif
          endif
        endif
        (cAlias)->(DbSkip(1))
      enddo
    endif
  endif
  if !::clsMetaBO:Save()
   ::mDelBook := .F.
   n := len(::maTran)
   for i := 1 to n
     (::maTran[i])->(WaCancel())
   next
   if (::cWa)->From_Arc
     _DbAreaClose(::mAliasSin)
     ::mAliasSin := ""
   endif

    if len(::aMsqNotSave) > 0 .And. ::lMsgErrShow
     Msg_s():arrShow(::aMsqNotSave,.T.)
    endif
    _DbAreaClose(::mAliasSin)
    return .f.
  endif
  ::mlHandSum := .F.
  ::mlSaveOnly := .F.
  n := Len(::maTran)
  for i := 1 to n
     (::maTran[i])->(WaSave())
  next
  if (::cWa)->From_Arc
    _DbAreaClose(::mAliasSin)
    ::mAliasSin := ""
  endif
  if ::mDelBook
    ::mDelBook := .F.
    For i := 1 to len(::maTbDoc)
      if len(::maTbDoc[i][3]) > 0
        (::maTbDoc[i][2])->(DbUnLock())
      else
        if len(::maTbDoc[i][4]) > 0
          (::maTbDoc[i][2])->(DbUnLock())
        endif
      endif
    next
    ::DelAllRec()
  endif
 //Записи в книгу делаем только если они еще не создавались или добавляем строки
  // если пересоздаем с-ф - все операции с записями
  // будут выполнены потом
  if !(::mParamIni[_TAX_QUE] == "0")
    if !::mlRePlaceMod .And. !::mReMakeBook .And. !::mDelRecBook
      ::BOOK:GoTop()
      if CanCreate("16",.f.) //после вызова из синьки нужно проверить
        //   F - только для регистрации из формы   F - при добавлении строк - вс-ф по которому не было регистрации   рекно - добавленного документа - при создании в существующий
        if ::mlCreateRec .And. (::mAliasInv)->MOVE_TP $ {"ЗК","ОТ","БП"} .And. ::mlReg .And. (::BOOK:Eof() .Or. !Empty(::mnRecAddDoc))
          GetRightTax(.F.,(::cWa)->TI_CTG,@aRight)
          if Len(aRight) == 1 .And. !aRight[1]
            lNewBook := .F.
          else
            if Len(aRight) > 1
              if !Empty(aRight[_NEW_])
                if ("ОП" $ aRight[_NEW_]) .Or. ("ОТ" $ aRight[_NEW_])
                  lNewBook := .F.
                endif
              endif
            endif
          endif
          if lNewBook
            ::CreateGroupRecInBook()
          endif
        endif
      //altd()
        if ::mlCreateRec .And. ::BOOK:Eof() .And. (::mAliasInv)->MOVE_TP $ {"ПП","ПР"} //((::mAliasInv)->MOVE_TP $ {"ПП","ПР"} .Or. (::mAliasInv)->STR_TP  $ {"0","1"})
          GetRightTax(.F.,(::cWa)->TI_CTG ,@aRight)
          if Len(aRight) == 1 .And. !aRight[1]
            lNewBook := .F.
          else
            if Len(aRight) > 1
              if !Empty(aRight[_NEW_])
                if (::cWa)->MOVE_TP == "ПР"
                  if ("АУ" $ aRight[_NEW_]) .Or. ("АВ" $ aRight[_NEW_])
                    lNewBook := .F.
                  endif
                else
                  if ("ПЛ" $ aRight[_NEW_])
                    lNewBook := .F.
                  endif
                endif
              endif
            endif
          endif
          if lNewBook
            ::CreateAVForBook()
          endif
        endif
      endif
    endif
  endif


  /*
  if ::BOOK:Eof() .And. ((::mAliasInv)->STR_TP  == "2") .And. ((::mAliasInv)->MOVE_TP  $ {"СЗ","СП"})
    ::CreateStorno()
  endif
  */
  //::mNotEd := .F.
  // очищаем массив RecNo заблокированных докумнтов
  // что бы при взятии на редактирование был пустым
  // раньше ачищать нельзя - используется в  CreateGroupRecInBook
  // CreateAVForBook , CreateStorno

  For i := 1 to len(::maTbDoc)
    if len(::maTbDoc[i][3]) > 0
      (::maTbDoc[i][2])->(DbUnLock())
    else
      if len(::maTbDoc[i][4]) > 0
        (::maTbDoc[i][2])->(DbUnLock())
      endif
    endif
  next
  for i := 1 to len(::maTbDoc)
    _DbAreaClose(::maTbDoc[i][2])
    _DbAreaClose(::maTbDoc[i][5])
  next
  ::maTbDoc := {}
  ::aSFDOC := {}

  if ::mReMakeBook .And. !(nReReg == 0)
    begin sequence
    oObjBook := clsTax_Book():New()
    oObjBook:Open()
    aBook := {}
    if !::BOOKST:EOF()
      ::BOOKST:GoTop()
      Do While !::BOOKST:Eof()
        if !(::BOOKST:CMP_TP $ "1,3")
          AADD(aBook,::BOOKST:RecNo())
        endif
        ::BOOKST:Skip(1)
      enddo
      for i := 1 to len(aBook)
         oObjBook:GoTo(aBook[i])
         oObjBook:Delete()
      next
    endif
    aBook := {}
    oObjBook:Scope(cDocId,cDocId,"TAG_REGDOC")
    oObjBook:GoTop()
    cIdOper := ""
    Do While !oObjBook:Eof()
      if  !(oObjBook:CMP_TP $ "1,3")
        if oObjBook:SF_ID == (::cWa)->Doc_Id
           cIdOper := oObjBook:TENTRY_ID
           AADD(aBook,oObjBook:RecNo())
         endif
       endif
       oObjBook:Skip(1)
    enddo
    for i := 1 to len(aBook)
       oObjBook:GoTo(aBook[i])
       oObjBook:Delete()
    next

    if nReReg == 1
    // Переформировать
        RegInBookDocSf((::cWa)->Doc_Id,cDocId,cJrn,,,,cIdOper,.F.)
    endif
    end sequence
    if ValType(oObjBook) == "O"
      oObjBook:Destroy()
      oObjBook := nil
    endif
  endif
  ::mDelRecBook := .F.
Return .T.
/////////////////////
//PG
// Заполнение значениями по умолчанию и переданными в создание параметрами
// Создаем записи измерений и дополнительных полей
// в зависимости от типа установленных в типе документа
method clsTax_Inv:Append()
local cKey,nDocType,nJrn,lPol,cNum := "",nNum := 1
//Local cOrder ,cNumMax,nLen
local cPodrazd := "", lRet := .F. ,cMsg , cDocNum := ""

  cKey := ""
  if Empty(::mModId) .And. Empty(::mParamIni[4])
    cMsg := "В настройке подсистемы Книга Покупок/Продаж " + CRLF
    cMsg := cMsg + " не определена налоговая модель."
    messagebox(cMsg,TITLEAPP,48)
    Return .F.
  endif
  if Empty(::mDocType) .And. Empty(::mParamIni[_TAX_DOCTYPE])
    cMsg := "В настройке подсистемы Книга Покупок/Продаж " + CRLF
    cMsg := cMsg + " не определен тип документа."
    messagebox(cMsg,TITLEAPP,48)
    Return .F.
  endif
  /*
  if ::mGroupSf .And. ::mTI_CTG == "1"// Получим номр для групповых приходных с-ф
    cOrder := ::DS:SetOrder("TAG_NUMDT")
    ::DS:Scope("1ГР","1ГР","TAG_NUMDT")
    ::DS:GoBottom()
    if ::DS:Eof() .Or. ::DS:Bof() .Or. Empty((::mAliasInv)->DOC_NUM)
      cNum := "ГР" + "0000000000000000000001"
    else
      cNumMax := (::mAliasInv)->DOC_NUM
      nNum := Val(Right(cNumMax,22))
      if Empty(nNum)
        cNum := "ГР" + "0000000000000000000001"
      else
        cNumMax := Alltrim(str(nNum + 1,22,0))
        nLen := Len(cNumMax)
        if nLen < 22
          cNum := "ГР" + replicate("0",22-nLen) + cNumMax
        else
          cNum := "ГР" + cNumMax
        endif
      endif
    endif
    ::DS:Scope()
    ::DS:SetOrder(cOrder)
  endif
  */
//altd()
  ::CanAdd := CanCreate('16', .f.)
  if ::CanAdd
    if  Empty(::mMove_Tp) .or. Empty(::mTI_CTG)
      MessageBox('Создание счета-фактуры. Не переданы параметры.',TITLEAPP,48)
      return .f.
    endif
    ::CanAdd := CanActionMoveTpForTax(self,.T.,_NEW_,::mTI_CTG,::mMove_Tp)
  endif
  if !::clsMetaBo:Append()
    ::mlHandSum := .F.
    return .f.
  endif
  ::mlHandSum := .T.
  lPol := if(::mTI_CTG =="1",.T.,.F.)
  //altd()

  if (::ObjDOC_TYPE)->(DbSeek(::mDocType))
    (::mAliasInv)->CODE_TP := (::ObjDOC_TYPE)->CODEDT
    (::mAliasInv)->DOC_TP := ::mDocType
  endif
  (::mAliasInv)->TI_CTG := ::mTI_CTG
  (::mAliasInv)->Move_Tp := ::mMove_Tp
  //(::mAliasInv)->Str_Tp := ::mStr_Tp

  //if !::mlIspr
    if Empty(::mDocDate)
      (::mAliasInv)->DOC_DATE := date()
    else
      (::mAliasInv)->DOC_DATE := ::mDocDate
    endif
    (::mAliasInv)->REG_DATE := (::mAliasInv)->DOC_DATE
  //else
  //  (::mAliasInv)->REG_DATE := date()
  //endif

  //(::mAliasInv)->DEP_DATE := Ctod("")
  ::VAL_ID := ::mVAL_ID  // пишем через интерфейс
  (::mAliasInv)->VAL_RATE := 1

  (::mAliasInv)->SUM_NNDS := 0
  (::mAliasInv)->SUM_NDS := 0
  (::mAliasInv)->SUM_A := 0
  (::mAliasInv)->SUM_BOOK := 0
  (::mAliasInv)->SUM_PAY := 0
  (::mAliasInv)->SUM_SHP := 0
  //(::mAliasInv)->SUM_USE := 0
  (::mAliasInv)->ST_SUM := 0
  (::mAliasInv)->COMMENT_m := ""
  (::mAliasInv)->COMPL_m := ""
  (::mAliasInv)->ACNT_ID := ""
  (::mAliasInv)->ANALIT := ""
  //(::mAliasInv)->ISTRANS := .F.
  (::mAliasInv)->IS_FULL := .F.

  (::mAliasInv)->STR_TP2 := .F.
  (::mAliasInv)->SHP_TP2 := 0
  (::mAliasInv)->STR_TP3 := .F.
  (::mAliasInv)->SHP_TP3 := 0
  (::mAliasInv)->STR_TP4 := .F.
  (::mAliasInv)->SHP_TP4 := 0
  (::mAliasInv)->STR_TP5 := .F.
  (::mAliasInv)->SHP_TP5 := 0
  (::mAliasInv)->MET_FORM := "1"
  (::mAliasInv)->ENT_ID := ::mEntId
  //(::mAliasInv)->ENT_ADDRID := ::mEntADDRId
  //(::mAliasInv)->ENT_LOC := GetPartnerAdd(::mEntADDRId,lPol)
  ::ENT_ADDRID := ::mEntADDRId
  if ::mParamIni[_TAX_USE_DOPNUM] .And. !::mlIspr  .And. (lPol .Or. !::mParamIni[_TAX_DNUM_RUL])
    (::mAliasInv)->DNUM := ::mParamIni[_TAX_INI_DOPNUM]
  endif
  if Empty(::mModId)
    (::mAliasInv)->MOD_ID  :=  ::mParamIni[4]
  else
    (::mAliasInv)->MOD_ID  := ::mModId
  endif
  (::mAliasInv)->PRT_TP  := "1"

  nDocType := ::mDocType
  if !::SetParamStrSum()
    Return .F.
  endif
  if ::mMove_Tp $ "ПП,ПР"
    if !(::TAX_STR:TAXSTRSUM:maModStr[1][_SUMUSE] == "2")
      messagebox("Налоговая модель для авансовых счетов фактур настроена некорректно.",TITLEAPP,48)
    endif
  endif
  //Заполним код подразделения
  if File(B6_DBF_PATH + "ufaschool.txt")
    lRet := .F.
    if LookUpSeek("tax\USER_PODR.dbf","TAG_USER",@lRet,Upper(m->B6_USER_NAME),"PODRAZD",@cPodrazd)
      IF lRet
        (::mAliasInv)->PODRAZD := cPodrazd
      ENDIF
    ENDIF
  endif

  nJrn := "1601"
  (::mAliasInv)->KORR := ::mlKorr
  (::mAliasInv)->DEF := ::mlIspr
  /*
  if !Empty(nDocType)
      if !GetDIMForDocType(::OBJDIM,nDocType,nJrn)
        ::Cancel()
        Return .F.
      endif
    endif
  */
  /*
    if !Empty(nDocType)
      if !GetParamForDocType(::PRM,nDocType,nJrn)
        ::Cancel()
        Return .F.
      endif
    endif
    */
  if (::mAliasInv)->TI_CTG == "2" .And. !(::mAliasInv)->DEF
    cKey := (::mAliasInv)->DOC_TP + left(DTOS((::mAliasInv)->DOC_DATE),4)
    cDocNum := F_EvalGetSFUrNumber( (::mAliasInv)->TI_CTG )
    ::LenNum()
    //if (::cWA)->KORR
    //  (::mAliasInv)->DOC_NUM := ::NumRule(1):NWDoc(cKey,"SFKORR")
    //else
      if Empty(cDocNum)
        (::mAliasInv)->DOC_NUM := ::NumRule(1):NWDoc(cKey,"SFDOC")//::NumRule:NWDoc(cKey,"SF")
      else
        (::mAliasInv)->DOC_NUM := cDocNum
        ::IsGenDocNum := .T.
      endif
    //endif
  endif
  /*
  if ::mGroupSf .And. ::mTI_CTG == "1"
    (::mAliasInv)->DOC_NUM := cNum
  endif
  */
  cKey := (::mAliasInv)->DOC_TP + left(DTOS((::mAliasInv)->REG_DATE),4)
  (::mAliasInv)->REG_NUM := ::NumRule(2):NWDoc(cKey,"SFREG")
  ::aSFDOC := {}
  ::mCardId := Space(22)//  карточка
  ::mCardPartner := Space(22)// партнер карточки расчетов
  ::mCardRecNo := 0
  ::mlSaveOnly := .F.
  //::mlCreateRec := .F.
return .T.

///////////
//PG
// Для установленного счета из плана счетов и идентификатора партнера
// если для данного счета есть измерение еспользующее
// справочник партнеров определяет значение кода сегмента аналитики и его полодение в
// полной аналитике
//  параметр lWrite ---
// при обращении из других объектов не нужно писать в базу
// Т - записываем F - нет
METHOD clsTax_Inv:GetAnalit(lWrite)
local  oErr,/*aAnalit,*/sAnalit:= ""
Local cSchet
local tbDim
local cAnalitSys := "",cSysName,cSysCode
local lFirst := .T.,s,lRet
 //altd()
 begin sequence
 cSchet := (::mAliasInv)->ACNT_ID
 if Empty(cSchet)
   Break(.T.)
 endif
  if Empty((::mAliasInv)->PRT_ID)
   Break(.T.)
 endif
 /*
 if Select(::mTbPSch) < 1
   _DbAreaOpen(B6_DBF_PATH + "Plan_sch.Dbf", @::mTbPSch, "CODE")
 endif
 */
 if (DIC_PLAN_SCH)->(DbSeek(Upper(cSchet)))
   if !(DIC_PLAN_SCH)->ANALIT_Y_N
     Break(.T.)
   Endif
 else
   Break(.F.)
 endif

 if Select(::mTbSeg) < 1
   _DbAreaOpen(B6_DBF_PATH + "Sch_seg.Dbf", @::mTbSeg, "SCHET")
 endif
 (::mTbSeg)->(OrdScope(0,Upper((::mAliasInv)->ACNT_ID)))
 (::mTbSeg)->(OrdScope(1,Upper((::mAliasInv)->ACNT_ID)))

 (::mTbSeg)->(DbGoTop())
 If (::mTbSeg)->(EOF())
   Break(.T.)
 endif

 tbDim := DIC_Dim_anl
 //_DbAreaOpen(B6_DBF_PATH + "dim_anl.Dbf", @tbDim, "ID")

 if (::mAliasInv)->PRT_TP == "1"
   if (DIC_PARTNER)->(DbSeek((::mAliasInv)->PRT_ID,.T.,"TAG_ID"))
     cSysName := (DIC_PARTNER)->ShortName
     cSysCode := (DIC_PARTNER)->Code
   else
     cSysName := ""
     cSysCode := ""
   endif
 elseif (::mAliasInv)->PRT_TP == "2"
 if (::mTbPeople)->(DbSeek((::mAliasInv)->PRT_ID,.T.,"TAG_IDP"))
     cSysName := (::mTbPeople)->ShortName
     cSysCode := (::mTbPeople)->Code
   else
     cSysName := ""
     cSysCode := ""
   endif
 endif

 do while !(::mTbSeg)->(EOF())
    (tbDim)->(DbSeek((::mTbSeg)->DIM_ID,.T.,"ID"))



    if ((tbDim)->SYS_ID == "0000000000000000000003" .And. (::mAliasInv)->PRT_TP == "1")  ;// 3  // есть измерение на справочнике партнеров
        .Or. ((tbDim)->SYS_ID == "0000000000000000000002" .And. (::mAliasInv)->PRT_TP == "2")
       if lFirst .Or. (tbDim)->ISSYSTEM  // системная аналитика перетирает остальные
          s := (tbDim)->ALG_CODE
          cAnalitSys := ""
          if (tbDim)->ISSYSTEM
            if !::GetPartnerEval((::mAliasInv)->PRT_ID,s,@cAnalitSys)
              Break(.F.)
            endif
          elseif (::mAliasInv)->PRT_TP == "1"
            lRet := .F.
            if GetAnalitByPartner((::mTbSeg)->DIM_ID,cSysName,cSysCode,@lRet,@cAnalitSys,.T.)
              if !lRet
                cAnalitSys := ""
              endif
            else
              cAnalitSys := ""
            endif
          else
            cAnalitSys := ""
          endif

          lFirst := .F.
        endif
        sAnalit += PADR(cAnalitSys,(tbDim)->LEN) + (::mTbSeg)->symbol
    elseif (::mAliasInv)->CNT_TYPE $ {"1","2"} .And. (::mAliasInv)->PRT_TP == "1"
      if !Empty((::mAliasInv)->CNT_DOC_ID)
        if (     (::mAliasInv)->CNT_TYPE == "1" ;
           .And. (tbDim)->DIM_ID == "0000000000000000001044" ;
           .And.(::mAliasInv)->TI_CTG == "1") ;
        .Or.  (     (::mAliasInv)->CNT_TYPE == "1" ;
           .And. (tbDim)->DIM_ID == "0000000000000000001045" ;
           .And.(::mAliasInv)->TI_CTG == "2") ;
        .Or. ((::mAliasInv)->CNT_TYPE == "2" .And. (tbDim)->DIM_ID == "0000000000000000001008")
           sAnalit += PADR(::GetBrg(4),(tbDim)->LEN) + (::mTbSeg)->symbol
        else
          sAnalit += Space((tbDim)->LEN) + (::mTbSeg)->symbol
        endif
      else
        sAnalit += Space((tbDim)->LEN) + (::mTbSeg)->symbol
      endif
    else
      sAnalit += Space((tbDim)->LEN) + (::mTbSeg)->symbol
    endif

    (::mTbSeg)->(DbSkip(1))
 enddo
 if !Empty(sAnalit)
   sAnalit := Left(sAnalit,len(sAnalit)-1)
 endif
 if  lWrite
   ::DS:FieldValue("ANALIT",sAnalit)
 endif


 //_DbAreaClose(tbDim)
 recover using oErr
  if  lWrite
    ::DS:FieldValue("ANALIT", "")
  endif
  //_DbAreaClose(tbDim)

  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence

Return .T.

Method clsTax_Inv:IsValMain(lRet)
  lRet := ((::mAliasInv)->VAL_ID == ::mVal_Id)
Return .T.

//aParam
///////////////
//PG
// создает строки С-Ф на основании документов
// aParam - массив RecNo документов на основании которых создавать
// cStrTp - тип строки
// lFromZakaz - T -  при пересоздании - аванс по заказу
// Т - успешное выполнение
/////////////
Method clsTax_Inv:CreateStrForDoc(aParam,cStrTp,cJRN,lFromZakaz)
local  oErr,nJrn,n,i,k ,cAlias,nRet
local cTbName,cTagDoc,cFieldName,lAv,lVMain //,cTagSF
local lChangedDoc := .F.,lObjDoc := .F. ,oObjDoc := nil,aLock := {}
 begin sequence
 //altd()

 if !(ValType(lFromZakaz) == "L") .Or.  !::mlRePlaceMod
   lFromZakaz := .F.
 endif
 if (Upper((::mAliasInv)->MOVE_TP) $ {'СЗ','СП'}) // записи сторно - суммы отрицательные
   ::mMultyStorno := -1
 else
   ::mMultyStorno := 1
 endif

 if (Upper((::mAliasInv)->MOVE_TP) $ {'ПР','ПП'})
   lAv := .T.  // Запись авансовая
 else
   lAv := .F.
 endif
 ::mParamIni := {}
 if !GetParamIni((::mAliasInv)->TI_CTG,lAv,@::mParamIni)
   messagebox("Не удалось инициализировать параметры настройки подсистемы КПП",TITLEAPP,48)
   Break(.F.)
 endif

 if Empty(::mParamIni[4])
   messagebox("Не определена налоговая модель в настройке подсистемы!",TITLEAPP,48)
   Break(.F.)
 endif
 /*
 if !Empty(::mcModId)
   ::mParamIni[4] := ::mcModId
 endif
 */
 if (::mAliasInv)->Val_Id == ::mVal_id
   lVMain := .T. // Валюта С-Ф совпадает с оновной валютой
 else
   lVMain := .F.
 endif


 if cStrTp == "4"
   if (::mAliasInv)->TI_CTG == "1"
     n := 5
   else
     n := 6
   endif
 else
   if Empty(cJRN)
     if CheckSubSystem("PM")
       do case
         case cStrTp == "0"
           n := 7
         case cStrTp == "1"
           n := 8
         case cStrTp == "2"
           n := 3
         case cStrTp == "3"
           n := 4
       endcase
     else
       n := val(cStrTp) + 1
     endif
   else
     do case
         case cJRN == "0101"
           n := 1
         case cJRN == "0201"
           n := 2
         case cJRN == "0301"
           n := 3
         case cJRN $ "0901,0904"
           n := 4
         case cJRN == "PM01"
           n := 7
         case cJRN == "PM02"
           n := 8
         case cJRN == "1701"
           n := 9
       endcase
   endif
 endif
 nJrn :=  ::aTab[n][5]
 k := AScan(::aTab,nJrn)
 n := AScan(::maTbDoc,nJrn)
 if n < 1
    AADD(::maTbDoc,{nJrn,,{},{},})
    i := Len(::maTbDoc)
    if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][1], @cAlias,::aTab[k][3])
       Break(.F.)
    endif
    ::maTbDoc[i][2] := cAlias
    if !(nJrn $ {"0101","0201","PM01","PM02"})
      if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][6], @cAlias,::aTab[k][7])
        Break(.F.)
      endif
      ::maTbDoc[i][5] := cAlias
    endif
    /*
    ::maTbDoc[i][2] := CreateDbRecord(B6_DBF_PATH + ;
                         ::aTab[k][1] ;
                         ,::aTab[k][2])
                         */
 else
   i := n
 endif

 if !::ReLockDocForSf(nJrn,aParam)
   Break(.F.)
 endif
 oObjDoc := ::maTbDoc[i][2]
 aLock := ::maTbDoc[i][4]

  do case
    case cStrTp == "0"
      if nJrn == "PM01" //CheckSubSystem("PM")
        if lFromZakaz .And. ::mlRePlaceMod
          if !::CreateForDoc51OrderRBook(oObjDoc,2,aLock)
            break(.F.)
          endif
        else
          if Empty((oObjDoc)->ACNT_ID)
            nRet := 1
          else
            if !::CheckRBook(oObjDoc,2,aLock,@nRet)
              break(.F.)
            endif
          endif
          if nRet == 1
            if !::CreateForFinDoc(oObjDoc,0,aLock)
              break(.F.)
            endif
          else
            if !::CreateForDoc51OrderRBook(oObjDoc,2,aLock)
              Break(.F.)
            endif
          endif
        endif
        /*
        if !::CreateForFinDoc(oObjDoc,0,aLock)
          Break(.F.)
        endif
        */
      else
        cTbName := ::aTab[1][1]
        cTagDoc := ::aTab[1][2]
        cFieldName :=  ::aTab[1][4]
        if lFromZakaz .And. ::mlRePlaceMod
          if !::CreateForDoc51OrderRBook(oObjDoc,0,aLock)
            break(.F.)
          endif
        else
          if !::CheckRBook(oObjDoc,0,aLock,@nRet)
            break(.F.)
          endif
          if nRet == 1
            if !::CreateForDoc51Order(oObjDoc,0,aLock)
              break(.F.)
            endif
          else
            if !::CreateForDoc51OrderRBook(oObjDoc,0,aLock)
              Break(.F.)
            endif
          endif
        endif
      endif

    case cStrTp == "1"
      if nJrn == "PM02" // CheckSubSystem("PM")
        if lFromZakaz .And. ::mlRePlaceMod
          if !::CreateForDoc51OrderRbook(oObjDoc,2,aLock)
            Break(.F.)
          endif
        else
          if Empty((oObjDoc)->ACNT_ID)
            nRet := 1
          else
            if !::CheckRBook(oObjDoc,2,aLock,@nRet)
              break(.F.)
            endif
          endif
          if nRet == 1
            if !::CreateForFinDoc(oObjDoc,1,aLock)
              Break(.F.)
            endif
          else
            if !::CreateForDoc51OrderRbook(oObjDoc,2,aLock)
              Break(.F.)
            endif
          endif
        endif

        /*
        if !::CreateForFinDoc(oObjDoc,1,aLock)
          Break(.F.)
        endif
        */
      else
        cTbName := ::aTab[2][1]
        cTagDoc := ::aTab[2][2]
        cFieldName :=  ::aTab[2][4]
        //::CreateForDoc51Order(oObjDoc,1,aLock)
        if lFromZakaz .And. ::mlRePlaceMod
          if !::CreateForDoc51OrderRbook(oObjDoc,1,aLock)
            Break(.F.)
          endif
        else
          if !::CheckRBook(oObjDoc,1,aLock,@nRet)
            break(.F.)
          endif
          if nRet == 1
            if !::CreateForDoc51Order(oObjDoc,1,aLock)
              Break(.F.)
            endif
          else
            if !::CreateForDoc51OrderRbook(oObjDoc,1,aLock)
              Break(.F.)
            endif
          endif
        endif
      endif

    case cStrTp == "2"
      cTbName := ::aTab[3][1]
      cTagDoc := ::aTab[3][2]
      cFieldName :=  ::aTab[3][4]
      if !::CreateForScladZapasTovarReal(oObjDoc,lVMain,0,aLock,::maTbDoc[i][5])
        Break(.F.)
      endif
    case cStrTp == "3"
      cTbName := ::aTab[4][1]
      cTagDoc := ::aTab[4][2]
      cFieldName :=  ::aTab[4][4]
      if !::CreateForScladZapasTovarReal(oObjDoc,lVMain,1,aLock,::maTbDoc[i][5])
        Break(.F.)
      endif
    case cStrTp == "4"
       if (::mAliasInv)->TI_CTG == "1"
         cTbName := ::aTab[5][1]
         cTagDoc := ::aTab[5][2]
         cFieldName :=  ::aTab[5][4]
         if !::CreateForScladZapasTovarReal(oObjDoc,lVMain,2,aLock,::maTbDoc[i][5])
           Break(.F.)
         endif
       else
         cTbName := ::aTab[6][1]
         cTagDoc := ::aTab[6][2]
         cFieldName :=  ::aTab[5][4]
         if !::CreateForScladZapasTovarReal(oObjDoc,lVMain,3,aLock,::maTbDoc[i][5])
           Break(.F.)
         endif
       endif
    case cStrTp == "5"
      if !::CreateForAssets(oObjDoc,aLock,::maTbDoc[i][5])
        Break(.F.)
      endif
  endcase

  // пересчитаем налоги  и суммы для  С_Ф
  ::CreateTaxForSF()
  oObjDoc := nil
 recover using oErr
  oObjDoc := nil
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence

Return .T.


/////////////////////////
//PG
//После удалении ссылки в документах - удаляются
//ссылки в строках этих документов
// valKey -  идентификатор д-та
// cTbName - таблица строк д-та
// cTag - индекс по идентификатору д-та в таблице строк
////////////////////////////
Method clsTax_Inv:ClearMarkForStrDocm(valKey,cTbName,cTag,cFieldName,cKeyStr,aStr,tb)//(valKey,cTbName,cTag,lAll,valKeyStr,lClDoc)
local  oErr
local i , lDel := .F.,cIdStr := ""
 cTbName := ""
  //altd()
 begin sequence
 //tb := CreateDbRecord(B6_DBF_PATH + cTbName)
 //if lAll
 (tb)->(OrdSetFocus(cTag))
 (tb)->(OrdScope(0,valKey))
 (tb)->(OrdScope(1,valKey))
  // tb:Scope(valKey,valKey,cTag)
  // tb:MoveFirst()
  (tb)->(DbGoTop())
   if ValType(aStr) == "A"
     Do while !(tb)->(Eof())
       lDel := .T.
       for i := 1 to Len(aStr)
         cIdStr :=  (tb)->&cKeyStr //tb:FieldValue(cKeyStr)
         if aStr[i][1] == cIdStr
           lDel := .F.
           if (tb)->(DbRLock())
             (tb)->&cFieldName := aStr[i][2]
             //(tb)->(DbRUnLock())
           else
             Break(.F.)
           endif
           //tb:FieldValue(cFieldName,aStr[i][2])
           //Exit
         endif
       next
       if lDel
         if (tb)->(DbRLock())
           (tb)->&cFieldName := Space(22) //tb:FieldValue(cFieldName,Space(22))
           //(tb)->(DbRUnLock())
         else
           Break(.F.)
         endif
       endif
       (tb)->(DbSkip(1)) //tb:MoveNext()
     enddo
   else
     Do while !(tb)->(Eof()) //!tb:Eof()
       if (tb)->(DbRLock())
         (tb)->&cFieldName := Space(22) //tb:FieldValue(cFieldName,Space(22)) //tb:OPER_FACT := "" //0
         //(tb)->(DbRUnLock())
       else
         Break(.F.)
       endif
       (tb)->(DbSkip(1)) //tb:MoveNext()
     enddo
   endif

 Break(.T.)
 recover using oErr
   /*
  if ValType(tb) == "O"
    tb:destroy()
    tb := nil
  endif
  */
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence

Return .T.

 */
////////////////////////
//PG
//Расчет сумм  по документу
/////////////////////
Method clsTax_Inv:CreateTaxForSF(lbase)
local  oErr ,a := {}
local cKey := 0,nPrior := 0 //nRec := ::TAX_STR:RecNo,
Local nSumNNds := 0,nSumNds :=0,nSumA := 0
//local aRecNo := ::aEditRec/*, aRecNoOld := {},aRecNoNew := {}*/ //aRecNo := ::mRecNo

Local nRecNo,cOldTag ,cKeyStr
//Local nRecStr,cTagStr
//Local cTaxId,cIdRate,nTaxRate,nTaxBase,nTaxSum
local dbStr,nRecNoStr, aDocTax := {}
Local i,n,lNotAdd := .T.,cIdA := "----------------------"
Local lKorr := (::cWa)->KORR
Local aMod :=  ::TAX_STR:TAXSTRSUM:maModStr
 begin sequence
 if len(aMod) == 0
   if !::SetParamStrSum()
     Break(.F.)
   endif
 endif
 for i := 1 to len(aMod)
   if AllTrim(aMod[i][_SYSNUM]) == "1"
     cIdA := aMod[i][_TAXID]
   endif
 next
 if ValType(lbase) != "L"
   lbase := .F.
 endif
//Пока всегда расчитываем налоги
 nRecNo := (::mAliasSum)->(RecNo())
 cOldTag := (::mAliasSum)->(OrdSetFocus("TAG_TAX"))// ::TAXSUM:SetOrder("TAG_TAX")
 cKey := (::mAliasInv)->Doc_ID + (::mAliasInv)->Doc_ID
 (::mAliasSum)->(OrdScope(0,cKey))
 (::mAliasSum)->(OrdScope(1,cKey))
 (::mAliasSum)->(dbGoTop())
 do while !(::mAliasSum)->(Eof())
   (::mAliasSum)->(DbRLock())
   if lbase
     a := {{(::mAliasSum)->TAX_IDRT,{(::mAliasSum)->TAX_BOOK,;
                                    (::mAliasSum)->TAX_ST,;
                                    (::mAliasSum)->BASE_BOOK,;
                                    (::mAliasSum)->BASE_ST}} ;
          }
   endif
   (::mAliasSum)->(DbDelete())
   (::mAliasSum)->(DbSkip(1))
 enddo
 (::mAliasSum)->(OrdSetFocus("TAG_STR"))
 // собираем суммы по строкам
 //создаем строки налогов под документ и заполняем
 (::mAliasStr)->(OrdSetFocus("Tag_DOC_ID"))
 ::TAX_STR:MoveFirst()
 dbStr := ::TAX_STR:DS
 nRecNoStr := dbStr:RecNo()
 do while !::TAX_STR:EOF()
   if lKorr .And. Empty(dbStr:STR_V)
     dbStr:MoveNext()
   endif
   ::TAX_STR:TAXSTRSUM:GoTop()

   nSumNNds := nSumNNds + (::mAliasStr)->SUM_NNDS
   nSumNds := nSumNds + (::mAliasStr)->SUM_NDS
   nSumA := nSumA + (::mAliasStr)->SUM_A

   //(::mAliasSum)->(OrdSetFocus("TAG_STR"))
   cKeyStr := (::mAliasStr)->STR_ID
   //(::mAliasSum)->(DbSeek(cKeyStr))
   Do while (::mAliasSum)->Str_ID == cKeyStr
     i := len(aDocTax)
     if i == 0
       if cIdA == (::mAliasSum)->TAX_ID .And. Round((::mAliasSum)->TAX_SUM,6) == 0
       else
         AADD(aDocTax,{(::mAliasSum)->TAX_ID,;
                       (::mAliasSum)->TAX_IDRT,;
                       (::mAliasSum)->TAX_RATE,;
                       (::mAliasSum)->TAX_BASE,;
                       (::mAliasSum)->TAX_SUM,;
                       (::mAliasSum)->PRIOR;
                       })
       endif
     else
       lNotAdd := .F.
       for n := 1 to i
         if cIdA == (::mAliasSum)->TAX_ID .And. Round((::mAliasSum)->TAX_SUM,6) == 0
         else
           if (::mAliasSum)->TAX_ID == aDocTax[n][1]
             if Empty((::mAliasSum)->TAX_IDRT) // Для акциза может не быть ставки
               if (::mAliasSum)->TAX_RATE == aDocTax[n][3]
                 lNotAdd := .T.
                 aDocTax[n][4] += (::mAliasSum)->TAX_BASE
                 aDocTax[n][5] += (::mAliasSum)->TAX_SUM
                 exit
               endif
             else
               if (::mAliasSum)->TAX_IDRT == aDocTax[n][2]
                 lNotAdd := .T.
                 aDocTax[n][4] += (::mAliasSum)->TAX_BASE
                 aDocTax[n][5] += (::mAliasSum)->TAX_SUM
                 exit
               endif
             endif
           endif
         endif
       next
       if !lNotAdd // Добавим налог и ставку
         if cIdA == (::mAliasSum)->TAX_ID .And. Round((::mAliasSum)->TAX_SUM,6) == 0
         else
           AADD(aDocTax,{(::mAliasSum)->TAX_ID,;
                       (::mAliasSum)->TAX_IDRT,;
                       (::mAliasSum)->TAX_RATE,;
                       (::mAliasSum)->TAX_BASE,;
                       (::mAliasSum)->TAX_SUM,;
                       (::mAliasSum)->PRIOR;
                       })
         endif
       endif
     endif

     (::mAliasSum)->(DbSkip(1))
   enddo
   */
   dbStr:MoveNext()
 enddo

 for n := 1 to len(aDocTax)
     (::mAliasSum)->(DbAppend())
     (::mAliasSum)->IDTAXSUM := XGUID()
     (::mAliasSum)->DOC_ID := (::mAliasInv)->DOC_ID
     (::mAliasSum)->STR_ID := (::mAliasInv)->DOC_ID
     (::mAliasSum)->TAX_ID := aDocTax[n][1]
     (::mAliasSum)->TAX_IDRT := aDocTax[n][2]
     (::mAliasSum)->TAX_RATE := aDocTax[n][3]
     (::mAliasSum)->TAX_BASE := aDocTax[n][4]
     (::mAliasSum)->TAX_SUM := aDocTax[n][5]
     (::mAliasSum)->PRIOR := aDocTax[n][6]
     (::mAliasSum)->IS_HAND := .F.
     if len(a) > 0
       for i := 1 to len(a)
         if a[i][1] == (::mAliasSum)->TAX_IDRT
           (::mAliasSum)->TAX_BOOK := a[i][2][1]
           (::mAliasSum)->TAX_ST := a[i][2][2]
           (::mAliasSum)->BASE_BOOK := a[i][2][3]
           (::mAliasSum)->BASE_ST := a[i][2][4]
         endif
       next
     endif

 next

 (::mAliasInv)->SUM_NNDS := nSumNNds
 (::mAliasInv)->SUM_NDS := nSumNds
 (::mAliasInv)->SUM_A := nSumA

 ::RaiseEvent("ChangedTaxStr"/*,aRecNo*/)
 (::mAliasSum)->(OrdSetFocus(cOldTag))
 (::mAliasSum)->(DbGoTo(nRecNo))
 ::TAX_STR:DS:GoTo( nRecNoStr)

 recover using oErr

  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence

Return .T.

Method  clsTax_Inv:lTaxNds(cTaxId)
Local lRet := .F.,i,n
Static aTax := {}
   n := len(aTax)
   for i := 1 to n
     if aTax[i][1] == cTaxId
       return aTax[i][2]
     endif
   next
   if Select(::mAliasTaxTp) < 1
     _DbAreaOpen(B6_DBF_PATH + "TAX\Tax_Tp.dbf", @::mAliasTaxTp, "TAG_ID")
   endif
   if (::mAliasTaxTp)->(DbSeek(cTaxId))
     if (alltrim((::mAliasTaxTp)->SYS_NUM) == '2')
       lRet := .T.
       AADD(aTax,{cTaxId,.T.})
     else
       lRet := .F.
       AADD(aTax,{cTaxId,.F.})
     endif
   endif
return lRet
//////////////////////////
//PG
// Получение массива RecNo
// документов взятых на редактирование
// aRecNo - массив возвращаемых значений
////////////////////////

Method clsTax_Inv:GetDocRecNo(aRecNo,nJrn)
//Local dbSfDoc := ::SFDOC:DS
local  oErr,n//,nRecNo := dbSfDoc:RecNo()
Local i//,cAlSfDoc := dbSfDoc:Alias()
//altd()
 begin sequence
 aRecNo := {}
 n := len(::aSfDoc)
 for i := 1 to n
   if nJrn == ::aSfDoc[i][_JRNID]
     if ::aSfDoc[i][_DOCID] == ::aSfDoc[i][_DOCSTRID]
       if !::aSfDoc[i][_DEL]
         AADD(aRecNo,::aSfDoc[i][_DOCRECNO])
       endif
     endif
   endif

 next
 //dbSfDoc:GoTop()
 //Do While !dbSfDoc:Eof()
 //  if (cAlSfDoc)->JRN_ID == nJrn
 //    i := AScan(::maTbDoc,nJrn)
 //    if i > 0
 //      aRecNo :=  ::maTbDoc[i][4]
 //    endif

 //  endif
 //  dbSfDoc:Skip(1)
 //enddo

 recover using oErr

  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.
//////////////////////////
//PG
//Отметка в массиве mParamDoc - удаленной строки С-Ф
// nStrId - идентификатор удаленной строки
//////////////////////////
Method clsTax_Inv:ClearMarkStrInDoc(nStrId)
local  oErr,m ,n,k, aDel := {},nJrn,cIdDoc
Local lDelDoc := .T.
Local dbSfDoc,cAlSfDoc
 begin sequence
 //altd()
 ***************************
 dbSfDoc := ::SFDOC:DS
 cAlSfDoc := dbSfDoc:Alias()
 dbSfDoc:GoTop()
 Do While !dbSfDoc:Eof()
   if (cAlSfDoc)->SFSTR_ID == nStrId
     AADD(aDel,dbSfDoc:RecNo())
     nJrn := (cAlSfDoc)->JRN_ID
     cIdDoc := (cAlSfDoc)->DOC_ID
   endif
   dbSfDoc:Skip(1)
 Enddo
 m := AScan(::maTbDoc,nJrn)
 For n := 1 to len(aDel)
   dbSfDoc:GoTo(aDel[n])
   dbSfDoc:Delete()
 next
 // У документов у которых есть строки
 if !(nJrn $ {"0101","0201"})
 // Проверим остались ли записи под данный документ
   dbSfDoc:GoTop()
   aDel := {}
   Do While !dbSfDoc:Eof()
     AADD(aDel,dbSfDoc:RecNo())
     if (cAlSfDoc)->DOC_ID == cIdDoc .And. !((cAlSfDoc)->DOCSTR_ID == cIdDoc)
       lDelDoc := .F.
     endif
   dbSfDoc:Skip(1)
   Enddo
   if lDelDoc
     For n := 1 to len(aDel)
       dbSfDoc:GoTo(aDel[n])
       dbSfDoc:Delete()
     next
   endif
 endif
 // Снимем блокировку у удаленных документов
 for n := 1 to len(aDel)
   //Документ не брался на редактирование
   if AScan(::maTbDoc[m][3],aDel[n]) < 0
     ::maTbDoc[m][2]:GoTo(aDel[n])
     ::maTbDoc[m][2]:UnLock()
   endif
   k := AScan(::maTbDoc[m][4],aDel[n])
   if k > 0
     ADel( ::maTbDoc[m][4], k )
     ASize( ::maTbDoc[m][4], Len(::maTbDoc[m][4])-1 )
   endif
 next

 recover using oErr

  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.
//////////////////////
//PG
// Возвращает в зависимости от типа строки С-Ф
// название таблицы строк документов, индекса идентификатора документа
// индекса идентификатора строк С-ф
// cStrTp - тип строк
// cTbName -  возвращает имя таблицы
// cTagDoc - индекс по идентификатору д-та
// cTagSf - индекс по идентификатору строк С-Ф
////////////////////
Method clsTax_Inv:SetStrDoc(nJrn/*cStrTp*/,cTbName,cTagDoc,cTagSf,cFieldName,cKeyName,cKeyStr)
local  oErr

 begin sequence
 //altd()

   do case
     case nJrn == "0301" //cStrTp == "2"
       cTbName := "Sclad\MDocm.dbf"
       cTagDoc := "TAG_OPER_"
       cTagSf := "TAG_FACT"
       cFieldName := "OPER_FACT"
       cKeyName := "NNOPER"
       cKeyStr := "NNOPERM"
     case nJrn $ "0901,0904" //cStrTp == "3"
       cTagSf := "TAG_FACT"
       cTbName := "Zapas\MDocm.dbf"
       cTagDoc := "TAG_OPER_"
       cFieldName := "OPER_FACT"
       cKeyName := "NNOPER"
       cKeyStr := "NNOPERM"
     case nJrn == "TV01" //1201 //cStrTp == "4"
       cTagSf := "TAG_FACT"
       cTagDoc :=  "TAG_NNOPER" //"TAG_OPER"
       cTbName := "TOVAR\ACT_OP.dbf"
       cFieldName := "OPER_FACT"
       cKeyName := "NNOPER"
       cKeyStr := "NNOPER"
     case nJrn == "0501" //cStrTp == "4"
       cTagSf := "TAG_FACT"
       cTagDoc :=  "TAG_NNOPER" //"TAG_OPER"
       cTbName := "REAL\ACT_OP.dbf"
       cFieldName := "OPER_FACT"
       cKeyName := "NNOPER"
       cKeyStr := "NNOPER"
   endcase

 recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

/////////////////////////
//PG
//Создание  после сохранения С-Ф по предоплате
//записи в книгу продаж
///////////////////////
Method clsTax_Inv:CreateAVForBook()
local  oErr,tb , aDoc := {}
local i,j,n,m
 begin sequence
//altd()
 if Len(::maTbDoc) < 1
   Break(.T.)
 endif
 n := len(::aSfDoc)
 for i := 1 to Len(::maTbDoc)
   //if !(ValType(::maTbDoc[i][2]) == "O")
   //  Loop
   //endif
   if  Len(::maTbDoc[i][4]) > 0 .Or. Len(::maTbDoc[i][3]) > 0
     tb := ::maTbDoc[i][2]
     if  Len(::maTbDoc[i][4]) > 0
       aDoc :=  ::maTbDoc[i][4]
     else
       aDoc :=  ::maTbDoc[i][3]
     endif
     for j := 1 to Len(aDoc) // ходим по выбранным документам
       if (abs((::mAliasInv)->SUM_A) - abs((::mAliasInv)->SUM_PAY) <= 0)
         Exit
       endif
       for m := 1 to n
         if ::maTbDoc[i][1] == ::aSfDoc[m][_JRNID]
           if aDoc[j] == ::aSfDoc[m][_DOCRECNO]
             //if ((tb)->KOP_NDS ==  ::KOP_NDS) .And. ;
             //   ((tb)->KOP_NNDS ==  ::KOP_NNDS) .And. ;
             //   ((tb)->KOP_NDS0 ==  ::KOP_NDS0) .And. ;
             //   ((tb)->KOP_AG_NDS ==  ::KOP_AG_NDS)

               (tb)->(DbGoTo(aDoc[j]))
               (tb)->(DbRUnLock(DbGoTo(aDoc[j])))
               ::CreateRecInBook(tb,::maTbDoc[i][1] $ "0101,PM01",::maTbDoc[i][1])
             //endif
           endif
         endif
       next
     next
   endif
 next
 //::mlCreateRec := .T.
 recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

Method clsTax_Inv:CreateRecInBook(tb,lBank,cJrn) //(i)
local  oErr
local aParam //:= {0,"2","АВ"} //, SumRec := 0
local oObjBook//, lBank := (::DS:STR_TP == "0")
 begin sequence
 //altd()

 if ::MOVE_TP == "ПР"
   if  (::cWa)->TI_CTG == "1"
     aParam := {0,(::cWa)->TI_CTG,"АУ"}
   else
     aParam := {0,(::cWa)->TI_CTG,"АВ"}
   endif
 else
   aParam := {0,(::cWa)->TI_CTG,"ПЛ"}
 endif
 oObjBook := clsTax_Book():New()
 oObjBook:Open()
 if !oObjBook:BeforeAppend(aParam)
   Break(.F.)
 endif
 if !oObjBook:Append()
   Break(.F.)
 endif
 oObjBook:SF_ID := (::mAliasInv)->DOC_ID
 //oObjBook:JRN_ID := iif(lBank,101,201)
 //if tb:Locked
 //  tb:UnLock()
 //endif
 if cJrn $ "PM01,PM02" //CheckSubSystem("PM")
   if   lBank
     oObjBook:JRN_ID := "PM01"
   else
     oObjBook:JRN_ID := "PM02"
   endif
   oObjBook:SRC_ID := (tb)->ROWID
 else
   if   lBank
     oObjBook:JRN_ID := "0101"
     oObjBook:SRC_ID := (tb)->NNOPER_ID //::tbDoc:NNOPER_ID
   else
     oObjBook:JRN_ID := "0201"
     oObjBook:SRC_ID := (tb)->NNOPER //::tbDoc:NNOPER//::mParams[1][i]
   endif
 endif

 if !oObjBook:Save()
 // Откроем форму книги
   if !StartFrmBook(oObjBook)
     oObjBook:Destroy()
   endif
 else
   oObjBook:Destroy()
 endif
 oObjBook := Nil
 recover using oErr
  if ValType(oObjBook) == "O"
    oObjBook:Destroy()
  endif
  oObjBook := Nil
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

/////////////////////////////
//PG
//Создание после сохранения С-Ф сторнирующих записей в Книгу покупок продаж
//при типе движения "СЗ","СП"
//////////////////////////
Method clsTax_Inv:CreateStorno()
local  oErr,tb
local i,j
 begin sequence
//altd()
 if Len(::maTbDoc) < 1
   Break(.T.)
 endif
 for i := 1 to Len(::maTbDoc)
   //if !(ValType(::maTbDoc[i][2]) == "O")
   //  Loop
   //endif
   if  Len(::maTbDoc[i][4]) > 0
     tb := ::maTbDoc[i][2]
     for j := 1 to Len(::maTbDoc[i][4]) // ходим по выбранным документам
       (tb)->(DbGoTo(::maTbDoc[i][4][j]))
       (tb)->(DbRUnLock(DbGoTo(::maTbDoc[i][4][j])))
       ::CreateStornoRecInBook(tb,::maTbDoc[i][1])
     next
   endif
 next

 recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.


Method clsTax_Inv:CreateStornoRecInBook(tb,nJrn)
local  oErr               // //????????
local oObjBook/*lSclad := (::mAliasInv)->STR_TP2,((::mAliasInv)->STR_TP == "2")*/,aParam := {}
 begin sequence
 //if !(ValType(tb/*::tbDoc*/) == "O")  //  нет документов
 //  Break(.T.)
 //endif
  //altd()
 oObjBook := clsTax_Book():New()
 oObjBook:Open()
 if (::mAliasInv)->TI_CTG == "1"
   aParam := {0,"1","ОП"}
 else

   aParam := {0,"2","ОТ"}
 endif
 if !oObjBook:BeforeAppend(aParam)
   Break(.F.)
 endif
 if !oObjBook:Append()
   Break(.F.)
 endif
 oObjBook:SF_ID := (::mAliasInv)->DOC_ID
 oObjBook:JRN_ID := nJrn//iif(lSclad,"0301","0901")
 //altd()
 oObjBook:SRC_ID := (tb)->nnoper //tb:FieldValue("nnoper")//::tbDoc:nnoper //::mParams[1][i]
 if !oObjBook:Save()
 // Откроем форму книги
   if !StartFrmBook(oObjBook)
     oObjBook:Destroy()
   endif
 else
   oObjBook:Destroy()
 endif
 oObjBook:Destroy()
 oObjBook := Nil

 recover using oErr
  if ValType(oObjBook) == "O"
    oObjBook:Destroy()
  endif
  oObjBook := Nil
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.
/*
Method clsTax_Inv:CreateArrayFromStr(tbStr,aRec,lValuta,lPrichod,;
                                     nRate,tbL_NDS,tbL_ACZ,lGroup,;
                                     nRecNo,cStrType,cMLabel)
local lRet := .T.
  if !CreateArrayFromStrForSF(tbStr,@aRec,lValuta,lPrichod,;
                                       nRate,tbL_NDS,tbL_ACZ,lGroup,;
                                       nRecNo,cStrType,cMLabel,;
                                       ::TAX_STR:TAXSTRSUM:maModStr,::mGroupSf,::mMultyStorno,;
                                       ::mRound,::mAliasInv)
     lRet := .F.
  endif
Return lRet
*/
////////////////////////////
//PG
//Формирование массива записей на основании строк
//выбранных для создания С-Ф документов
// рассчитывается сумма налогов
// tbStr - рабочая область строк//рекордсет строк для выбранного д-та
// aRec -  массив возвращаемых значение
// lValuta -  флаг валютного д-та
// lPrichod - флаг прихода
// nRate - курс д-та
// tbL_NDS - вхождение в цену НДС
// tbL_ACZ - вхождение в цену Акциза
// lGroup - признак группировки одинаковых строк
// nRecNo - RecNo документа
// cStrType - тип строки
// cMLabel - рабочая область артикулов
// lMul - Т - документов несколько, иначе один
//!!!!!!!!!!!! Изменения синхронизировать с Function CreateArrayFromStrForSF
Method clsTax_Inv:CreateArrayFromStr(tbStr,aRec,lValuta,lPrichod,;
                                     nRate,tbL_NDS,tbL_ACZ,lGroup,;
                                     nRecNo,cStrType,cMLabel,nStr,lMul)
local  oErr
local aRecSort := {},i ,cKey := "",aRecOneDoc := {} // массив строк одного документа одного
local n := 0 , aRecSortSum := {},nPrior := 0,nBaseS := 0
local nBaseN := 0,nTaxN := 0,nBaseA := 0,nTaxA := 0,nSumOut := 0
local nRateA := 0,nRateN := 0,nTaxSumA := 0,nTaxSumN := 0
local nTaxSumBaseA := 0, nTaxSumBaseN := 0,nTaxSumBaseAN := 0, nTaxSumBaseNN := 0
local nSumNNDS := 0,nSumNDS := 0,nSumA := 0,nVozvrat := 1
local a := {},k,lExit := .F. //,TaxId
local cIdRateA := "" ,lRet,cMsg := "" ,mTax := 0 ,cJrn := ""

local cIdRateN := ""
Local lVozvrat := .F.,lVozvratMsg := .F.//,nKolOsn := 0
Local nBr := 0,nVoz :=0,nBrOsn := 0,nVozOsn :=0
Local waGrup := "" ,cTbGrup := "" ,lYesNds := .F.,nNds := 0
Local aModStr :=  ::TAX_STR:TAXSTRSUM:maModStr
Local aStr := {}
Local j
 begin sequence
 //altd()
 /*
 if !(ValType(::objModStr) == "O")
   ::objModStr :=clsMod_Str():New()
   ::objModStr:Open()
   //::objModStr:Scope(str(::mParamIni[4],10,0),str(::mParamIni[4],10,0),"TAG_PRIOR")
   ::objModStr:Scope(::mParamIni[4],::mParamIni[4],"TAG_PRIOR")
 endif
 */
 //39698 - сохраняем порядок ввода как в накладных и актах
 if cStrType $ {"2","3"}
      //AADD(aStr, {(tbStr)->NUMSTR,(tbStr)->(RecNo())})
     if cStrType = "2"
       cTbGrup := "sclad\mgrup.dbf"
       cJrn := "0301"
     else
       cTbGrup := "zapas\mgrup.dbf"
       cJrn := "0901"
     endif
     if ! _DbAreaOpen(B6_DBF_PATH + cTbGrup, @waGrup,"MGRUP")
       Break(.F.)
     endif
 endif
 do while !(tbStr)->(EOF())
   if cStrType $ {"2","3"}

     if (waGrup)->(DbSeek(Upper((tbStr)->GRUP)))
        if !((waGrup)->TYPE == "3")
           AADD(aStr, {(tbStr)->NUMSTR,(tbStr)->(RecNo())})
        endif
     endif

   else
     AADD(aStr, {(tbStr)->NUMPP,(tbStr)->(RecNo())})
   endif
   (tbStr)->(DbSkip(1))
 enddo
 aStr := ASort(aStr,,,{|aX,aY|aX[1] < aY[1]})

 for j := 1 to len(aStr)
   nStr ++
   (tbStr)->(DbGoTo(aStr[j][2]))
   do case
     case cStrType $ {"2","3"}
       cIdRateN := ""

       /////////////////////////////
       if (tbStr)->NONDS
         if !CheckIdRateForRate(,(tbStr)->NDS,@cIdRateN,,"2",(tbStr)->NONDS)
           messagebox(" Не удалось получить идентификатор ставки для НДС!",TITLEAPP,48)
           Break(.F.)
         endif
       else
         if (waGrup)->(DbSeek(Upper((tbStr)->GRUP)))
           cIdRateN := (waGrup)->oper_nds
         endif
         // Проверим соответствие идентификатора - ставке
          if !Empty(cIdRateN)
            lRet := .F.
            if !LookUpSeek("SPR_NDS","TAG_OPER",@lRet,cIdRateN,"nds",@nNds)
              Break(.F.)
            endif
            if lRet
              IF !(nNds == (tbStr)->NDS)
                cIdRateN := ""
              ENDIF
            else
              cIdRateN := ""
            endif
          endif
         if Empty(cIdRateN)
           if !CheckIdRateForRate(,(tbStr)->NDS,@cIdRateN,,"2",(tbStr)->NONDS)
             messagebox(" Не удалось получить идентификатор ставки для НДС!",TITLEAPP,48)
             Break(.F.)
           endif
         endif
       endif
       if Empty(cIdRateN)
         messagebox(" Не удалось получить идентификатор ставки для НДС!",TITLEAPP,48)
         Break(.F.)
       endif

 //////////////////////////////////


     // Получаем идентификатор ставки для акциза
       cIdRateA := ""
       //TaxId := ""
       if !Empty((tbStr)->SUM_ACZ)
         // Получаем идентификатор Акциза
         if !CheckIdRateForRate(,(tbStr)->PA,@cIdRateA,,"1")
           messagebox(" Не удалось получить идентификатор ставки для Акциза!",TITLEAPP,48)
           Break(.F.)
         endif
         //28296 pg идентификатора акциза с 0 ставкой может не  быть
         if Empty(cIdRateA) .And. !Empty((tbStr)->PA)
           if !CreateApRate((tbStr)->PA,@cIdRateA)
             Break(.F.)
           endif
         endif
         /*
         lRet := .F.
         if !LookUpLocate("TAX\Tax_Tp.dbf","Upper(Alltrim(SYS_NUM)) == '1'",@lRet,"TAX_ID",@TaxId)
           Break(.F.)
         endif
         if !lRet
           Break(.F.)
         endif
         // получаем идентификатор ставки по ставке
         cKey := TaxId + str(tbStr:PA,19,5)
         lRet := .F.
         if !LookUpSeek("SPR_NDS","TAG_IDNDS",@lRet,cKey,"NNOPER",@cIdRateA)
           Break(.F.)
         endif
         if !lRet
           cIdRateA := ""
           // Если не нашли ставку - создаем акциз
           if !CreateApRate(tbStr:PA,@cIdRateA)
             Break(.F.)
           endif
         endif
         */
       endif
       // Для передачи на консигнацию - проверяем на возврат
       // при обработке не групповых с-ф
       //nKolOsn := (tbStr)->KOL
       if (tbStr)->Vid == "2" .And. (tbStr)->Type == "3" .And. !::mGroupSf
         if (tbStr)->Kol2 > 0 .And. !lVozvratMsg
           lVozvratMsg := .T.
           cMsg := "По накладной №" + (tbStr)->numdoc + " от " +  DTOC((tbStr)->date) + "был возврат." + chr(13) + chr(10)
           cMsg += "Сформировать счет-фактуру с учетом возврата?"
           n := messagebox(cMsg,TITLEAPP,36)
           if n == 6
             lVozvrat := .T.
           endif
         endif
       endif
       if lVozvrat
         nVozOsn := (tbStr)->Kol2
         //Calc_KolFromEd(grup,nnum,qnty,unitnew,cAlias,newR,cJrn,cMDim)
         nVoz := Calc_KolFromEd((tbStr)->grup,;
                                      (tbStr)->nnum,;
                                      (tbStr)->Kol2,;
                                      (tbStr)->ED1,cMLabel,(tbStr)->R,cJrn,(tbStr)->MDIM)
       else
         nVozOsn := 0
         nVoz := 0
       endif
       // Для закупки проверяем брак и недостачу
       if (tbStr)->Vid == "1"
         nBrOsn :=  (tbStr)->kolned + (tbStr)->kolbr
         nBr    := nBrOsn
         if !(nBrOsn == 0)//nBrOsn > 0 //есть брак или недостача
         //пересчитаем количество в ед измерения документа
           if (cMLabel)->(DbSeek(Upper((tbStr)->GRUP+(tbStr)->NNUM)))
             if !((tbStr)->ED1 == (cMLabel)->ED) //Документ не в основных ед
                nBr := Calc_KolFromEd((tbStr)->grup,;
                                      (tbStr)->nnum,;
                                       nBrOsn,;
                                      (tbStr)->ED1,cMLabel,(tbStr)->R,cJrn,(tbStr)->MDIM)

             endif
           endif
         else
           nBrOsn := 0
           nBr := 0
         endif
       endif

                   //          1               добавлена аналитика
       aadd(aRecOneDoc,{(tbStr)->GRUP + (tbStr)->NNUM + (tbStr)->MDIM + (tbStr)->PARTIA + (tbStr)->ED1 + str((tbStr)->cenaout,19,8) +  if(tbL_NDS,"1","0")+if(tbL_ACZ,if((tbStr)->SUM_ACZ=0,"0","1"),"0") ,;
              ; // 2             3           4
              (tbStr)->GRUP,(tbStr)->NNUM,(tbStr)->PARTIA, ;
              ; // 5              6              7 - для валютной С-Ф - берем сумму в валюте д-та
              (tbStr)->ED1,{(tbStr)->KOLOUT,(tbStr)->KOL}, iif(lValuta,(tbStr)->SUMOUTR / nRate ,(tbStr)->SUMOUTR),;
               ; //  8 для валютной С-Ф сумму налогов пересчитываем в валюту С-Ф  9
              iif(lValuta,(tbStr)->SUM_NDS / nRate,(tbStr)->SUM_NDS),iif(lValuta,(tbStr)->SUM_ACZ / nRate,(tbStr)->SUM_ACZ),;
              ;//10 Д-нт,  Строка д-та  //работаем от RecNo
              {{nRecNo,(tbStr)->(RecNo()),(tbStr)->nnoperm, nStr}},; //{{nRecNo,tbStr:NUMSTR}},;nnoperm
              ; // 11       12
              (tbStr)->NDS,(tbStr)->PA,;
              ; // 13  14        15          16
              nRateA,nTaxSumA,nTaxSumBaseA,nTaxSumBaseAN,;
              ;// 17   18        19           20           21
              nRateN,nTaxSumN,nTaxSumBaseN,nTaxSumBaseNN,nBaseS,;
              ;//  22    23      24
              nSumNNDS,nSumNDS,nSumA ,;
              ;// 25              26
              (tbStr)->R,iif(lValuta,(tbStr)->CENAOUT,(tbStr)->CENAOUT * nRate)*::mMultyStorno,;
              ;// 27        28         29        30            31 недостача + брак,32 - возврат ,33 - ндс в цене акциз в цене
              (tbStr)->VID,cIdRateA,cIdRateN,(tbStr)->MDIM,{nBr,nBrOsn},{nVoz,nVozOsn},{tbL_NDS,tbL_ACZ} })  //tbStr:Oper_Nds })  //
     case cStrType == "4"
       lRet := .F.
       nRateN := 0
       if !Empty((tbStr)->Oper_Nds) // по идентификатору - получаем ставку
         if !LookUpSeek("SPR_NDS.Dbf","TAG_OPER",@lRet,(tbStr)->Oper_Nds,"nds",@nRateN)
           messagebox(" Не удалось получить значение ставки для НДС!",TITLEAPP,48)
           Break(.F.)
         endif
         if !lRet
           messagebox(" Не удалось получить значение ставки для НДС!",TITLEAPP,48)
           Break(.F.)
         endif
       endif            //          1
       aadd(aRecOneDoc,{(tbStr)->GRUP + (tbStr)->NNUM + str((tbStr)->CENA)+  if(tbL_NDS,"1","0")+if(tbL_ACZ,if((tbStr)->SUM_ACZ=0,"0","1"),"0"), ;
              ; // 2               3      4
              (tbStr)->GRUP,(tbStr)->NNUM,"", ;
              ; // 5   6          7 - для валютной С-Ф - берем сумму в валюте д-та
               "",{(tbStr)->KOL,(tbStr)->KOL}, iif(lValuta,(tbStr)->SUMMA / nRate,(tbStr)->SUMMA),;
              ; //  8 для валютной С-Ф сумму налогов пересчитываем в валюту С-Ф 9
              iif(lValuta,(tbStr)->SUM_NDS / nRate,(tbStr)->SUM_NDS),0,;
              ;//10 Д-нт,  Строка д-та
              {{nRecNo,(tbStr)->(RecNo()),(tbStr)->NNOPER,nStr}},; //{{nRecNo,tbStr:NNOPER}},;
              ; //11       12
                nRateN,0,;
              ; // 13  14        15          16
              nRateA,nTaxSumA,nTaxSumBaseA,nTaxSumBaseAN,;
              ;// 17   18        19           20           21
              nRateN,nTaxSumN,nTaxSumBaseN,nTaxSumBaseNN,nBaseS,;
              ;//  22    23      24
              nSumNNDS,nSumNDS,nSumA ,;
              ;// 25                           26                                27    28      29               30 31 - брак + недостача,32 - возврат,33 - ндс в цене, акциз в цене
               1,iif(lValuta,(tbStr)->CENA,(tbStr)->CENA * nRate)*::mMultyStorno,"",cIdRateA,(tbStr)->Oper_Nds,"",{0,0},{0,0},{tbL_NDS,tbL_ACZ} }) //
   endcase
   //(tbStr)->(DbSkip(1))
 next
 //enddo
 aStr := {}
 if lGroup
   for i := 1 to len(aRecOneDoc)
     AADD(aStr,aRecOneDoc[i])
   next
   aRecSort := ASort(aRecOneDoc,,,{|aX,aY|aX[1] < aY[1]})
   if !lMul
   // Если документ один - пробуем сохранить порядок ввода документа
     cKey := ""
     lGroup := .F.
     for i := 1 to len(aRecSort)
       if cStrType == "4"
         if cKey == aRecSort[i][1]
           lGroup := .T.
           exit
         else
           cKey := aRecSort[i][1]
         endif

       else
         if cKey == aRecSort[i][1] + aRecSort[i][27]
           lGroup := .T.
           exit
         else
           cKey := aRecSort[i][1] + aRecSort[i][27]
         endif
       endif
     next
   endif
   if !lGroup
     aRecSort := aStr
   endif
 else
   aRecSort := aRecOneDoc
 endif
 aRecOneDoc := {}
 /*
 cKey := ""
 if lGroup
   for i := 1 to len(aRecSort)
     if cKey == aRecSort[i][1]
       aRecSortSum[n][6][1] := aRecSortSum[n][6][1] + aRecSort[i][6][1]
       aRecSortSum[n][6][2] := aRecSortSum[n][6][2] + aRecSort[i][6][2]
       aRecSortSum[n][7] := aRecSortSum[n][7] + aRecSort[i][7]
       aRecSortSum[n][8] := aRecSortSum[n][8] + aRecSort[i][8]
       aRecSortSum[n][9] := aRecSortSum[n][9] + aRecSort[i][9]
       aRecSortSum[n][31][1] := aRecSortSum[n][31][1] + aRecSort[i][31][1]
       aRecSortSum[n][31][2] := aRecSortSum[n][31][2] + aRecSort[i][31][2]
       aRecSortSum[n][32][1] := aRecSortSum[n][32][1] + aRecSort[i][32][1]
       aRecSortSum[n][32][2] := aRecSortSum[n][32][2] + aRecSort[i][32][2]
       //aRecSortSum[n][10] := AADD(aRecSortSum[n][10] ,{aRecSort[i][10]})
       AADD(aRecSortSum[n][10] ,aRecSort[i][10][1])
     else
       AADD(aRecSortSum,aRecSort[i])
       cKey := aRecSort[i][1]
       n:= n +1
     endif
   next
 else
 */
   aRecSortSum := aRecSort
   aRecSort := {}
 //endif
 // рассчитываем налоги по строкам
 for n := 1 to  len(aRecSortSum)
 nBaseN := 0
 nTaxN := 0
 nBaseA := 0
 nTaxA := 0
 nSumOut := 0
 nPrior := 0
 nBaseS := 0
 nRateA := 0
 nRateN := 0
 nTaxSumA := 0
 nTaxSumN := 0
 nTaxSumBaseA := 0
 nTaxSumBaseN := 0
 nTaxSumBaseAN := 0
 nTaxSumBaseNN := 0
 nSumNNDS := 0
 nSumNDS := 0
 nSumA := 0

 //Сумма по строке
 nSumOut := aRecSortSum[n][7] //tbStr:SUMOUTR
 nSumOut :=  BS_ROUND(nSumOut,::mRound/*(DIC_VALUTA)->ACCURACY*/)

 // - если в документе ставка НДС ненулевая и сумма ненулевая - НДС в счете-фактуре переносим из документа
 // - если в документе ставка НДС ненулевая и сумма нулевая - НДС считаем по ставке
 // - если в документе ставка нулевая - в счете-фактуре считаем по ставке, не глядя на сумму НДС
 //  28059 нужно сделать как можно срочнее  . клиенту решено отдать dll ну во первых утверждение 2 и 3 не верно. Всегда переносим из документа.
 if tbL_NDS

   nTaxN := aRecSortSum[n][8]
   nTaxN :=  BS_ROUND(nTaxN,::mRound)
   nBaseN := nSumOut - nTaxN
   if !(cStrType == "4")
     if tbL_ACZ
      //  если НДС в цене - базовая сумма без суммы НДС

       // 28296 pg ставки у акциза может не быть
       if !Empty(aRecSortSum[n][9])
         nTaxA := aRecSortSum[n][9]
       elseif Empty(aRecSortSum[n][9]) //.And. !Empty(aRecSortSum[n][12])
         nTaxA := 0 //(nBaseN * (aRecSortSum[n][12])/(100+aRecSortSum[n][12]))
       elseif Empty(aRecSortSum[n][12])
         nTaxA := 0
       endif
       nTaxA :=  BS_ROUND(nTaxA,::mRound)
       nBaseA := nBaseN - nTaxA
     else
       if lPrichod
         if !Empty(aRecSortSum[n][9])
           nTaxA := aRecSortSum[n][9]
         elseif Empty(aRecSortSum[n][9]) //.And. !Empty(aRecSortSum[n][12])
           nTaxA := 0//(nBaseN * (aRecSortSum[n][12])/(100+aRecSortSum[n][12]))
         elseif Empty(aRecSortSum[n][12])
           nTaxA := 0
         endif
       else
         nTaxA := aRecSortSum[n][9]
       endif
       nTaxA :=  BS_ROUND(nTaxA,::mRound)
       nBaseA := nBaseN
     endif
   endif
 else
   if !Empty(aRecSortSum[n][8]) .And. !Empty(aRecSortSum[n][11])
     nTaxN := aRecSortSum[n][8]
   elseif Empty(aRecSortSum[n][8]) //.And. !Empty(aRecSortSum[n][11])
     nTaxN := 0//(nSumOut * (aRecSortSum[n][11])/(100+aRecSortSum[n][11]))
   elseif Empty(aRecSortSum[n][11])
     nTaxN := 0
   endif
   nTaxN :=  BS_ROUND(nTaxN,::mRound)
   nBaseN := nSumOut
   if !(cStrType == "4")
     if tbL_ACZ
       if !Empty(aRecSortSum[n][9])
         nTaxA := aRecSortSum[n][9]
       elseif Empty(aRecSortSum[n][9]) //.And. !Empty(aRecSortSum[n][12])
         nTaxA := 0//(nSumOut * (aRecSortSum[n][12])/(100+aRecSortSum[n][12]))
       elseif Empty(aRecSortSum[n][12])
         nTaxA := 0
       endif
       nTaxA :=  BS_ROUND(nTaxA,::mRound)
       nBaseA := nBaseN - nTaxA
     else
       if lPrichod
         if !Empty(aRecSortSum[n][9])
           nTaxA := aRecSortSum[n][9]
         elseif Empty(aRecSortSum[n][9]) //.And. !Empty(aRecSortSum[n][12])
           nTaxA := 0//(nBaseN * (aRecSortSum[n][12])/(100+aRecSortSum[n][12]))
         elseif Empty(aRecSortSum[n][12])
           nTaxA := 0
         endif
       else
         nTaxA := aRecSortSum[n][9]
       endif
       nTaxA :=  BS_ROUND(nTaxA,::mRound)
       nBaseA := nBaseN
     endif
   endif
 endif
  //altd()
  //::objModStr:MoveFirst()
  //do while !::objModStr:EOF()
  nSumNNDS := nSumOut
  nSumA := nSumOut
  for i := 1 to len(aModStr)
    mTax := 0
    do case //&&&&
      case ((Alltrim(aModStr[i][_SYSNUM]) == "1")  .And. !(cStrType == "4"))// Акциз//((Alltrim(::objModStr:TAX_TP:SYS_NUM) == "1")  .And. !(cStrType == "4"))// Акциз
         nRateA := aRecSortSum[n][12]
         nTaxSumA := nTaxA  * ::mMultyStorno
         mTax := nTaxSumA
         //48804
         if (aModStr[i][_SUMUSE] == "2")
         //Налоговая модель применяется к полю Стоимость с НДС (SUM_USE=2) Это значит - у нас НДС извлекается; акциз извлекается
           if tbL_ACZ .And. tbL_NDS
           //TAX_SUM.TAX_BASE= MDOCM.SUMOUTR - MDOCM.SUM_NDS если MDOC. L_ACZ= true(входит) и MDOC. L_NDS=true(входит)
             nTaxSumBaseA := nSumOut - nTaxN  * ::mMultyStorno
           elseif tbL_ACZ .And. !tbL_NDS
           //TAX_SUM.TAX_BASE= MDOCM.SUMOUTR если MDOC. L_ACZ= true(входит) и MDOC. L_NDS=true(не входит)
             nTaxSumBaseA := nSumOut
           elseif !tbL_ACZ .And. !tbL_NDS
           //TAX_SUM.TAX_BASE= MDOCM.SUMOUTR + MDOCM.SUM_ACZ если MDOC. L_ACZ= true( не входит) и MDOC. L_NDS=true(не входит)
             nTaxSumBaseA := nSumOut +  nTaxSumA
           endif
         else
         //Налоговая модель применяется к полю Стоимость (SUM_USE=1) Это значит у нас НДС начисляется; акциз извлекается
           if tbL_ACZ .And. tbL_NDS
           //TAX_SUM.TAX_BASE= MDOCM.SUMOUTR - MDOCM.SUM_NDS если MDOC. L_ACZ= true(входит) и MDOC. L_NDS=true(входит)
             nTaxSumBaseA := nSumOut - nTaxN  * ::mMultyStorno
           elseif tbL_ACZ .And. !tbL_NDS
           //TAX_SUM.TAX_BASE= MDOCM.SUMOUTR если MDOC. L_ACZ= true(входит) и MDOC. L_NDS=true(не входит)
             nTaxSumBaseA := nSumOut
           elseif !tbL_ACZ .And. !tbL_NDS
           //TAX_SUM.TAX_BASE= MDOCM.SUMOUTR + MDOCM.SUM_ACZ если MDOC. L_ACZ= true( не входит) и MDOC. L_NDS=true(не входит)
             nTaxSumBaseA := nSumOut +  nTaxSumA
           endif
         endif
         /*
         if tbL_ACZ // в документе налог в том числе
         //nBaseN := nSumOut - nTaxN
           if aModStr[i][_CALCRL] // Налог извлекатся
             nTaxSumBaseA := nBaseA * ::mMultyStorno + nTaxSumA
           else
             nTaxSumBaseA := nBaseA * ::mMultyStorno
           endif
         else //кроме того
         //nBaseN := nSumOut
           if aModStr[i][_CALCRL] // Налог извлекатся
             nTaxSumBaseA := nBaseA * ::mMultyStorno + nTaxSumA
           else
             nTaxSumBaseA := nBaseA * ::mMultyStorno
           endif
         endif
         */
         /*
         if !aModStr[i][_CALCRL] .And. !tbL_ACZ//начисляется
           // соответствует налоговой модели С-Ф к сумму без налога + налог

              nTaxSumBaseA := nBaseA * ::mMultyStorno + nTaxSumA

         else //извлекается
            nTaxSumBaseA := nBaseA * ::mMultyStorno

         endif
         */
         /*
         if nPrior == 0
            nBaseS := nTaxSumBaseA
         endif
         */

      // для НДС привести суммы в соответствие с налоговой моделью
      case Alltrim(aModStr[i][_SYSNUM]) == "2"//Alltrim(::objModStr:TAX_TP:SYS_NUM) == "2" // НДС
         nRateN := aRecSortSum[n][11]
         nTaxSumN := nTaxN  * ::mMultyStorno
         mTax := nTaxSumN
         //48804
         if (aModStr[i][_SUMUSE] == "2")
         //Налоговая модель применяется к полю Стоимость с НДС (SUM_USE=2) Это значит - у нас НДС извлекается; акциз извлекается
           if tbL_ACZ .And. tbL_NDS
           //TAX_SUM.TAX_BASE= MDOCM.SUMOUTR если MDOC. L_ACZ= true(входит) и MDOC. L_NDS=true(входит)
             nTaxSumBaseN := nSumOut
           elseif tbL_ACZ .And. !tbL_NDS
           //TAX_SUM.TAX_BASE= MDOCM.SUMOUTR + MDOCM.SUM_NDS если MDOC. L_ACZ= true(входит) и MDOC. L_NDS=true(не входит)
             nTaxSumBaseN := nSumOut + nTaxSumN
           elseif !tbL_ACZ .And. !tbL_NDS
           //TAX_SUM.TAX_BASE= MDOCM.SUMOUTR + MDOCM.SUM_ACZ + MDOCM.SUM_NDS если MDOC. L_ACZ= true( не входит) и MDOC. L_NDS=true(не входит)
             nTaxSumBaseN := nSumOut + nTaxSumN + nTaxA  * ::mMultyStorno
           elseif !tbL_ACZ .And. tbL_NDS
           //TAX_SUM.TAX_BASE= MDOCM.SUMOUTR если MDOC. L_ACZ= false( не входит) и MDOC. L_NDS=true(входит) - это значит АКЦИЗА в модели склада НЕТ
             nTaxSumBaseN := nSumOut
           endif
         else
         //Налоговая модель применяется к полю Стоимость (SUM_USE=1) Это значит у нас НДС начисляется; акциз извлекается
           if tbL_ACZ .And. tbL_NDS
           //TAX_SUM.TAX_BASE= MDOCM.SUMOUTR - MDOCM.SUM_NDS если MDOC. L_ACZ= true(входит) и MDOC. L_NDS=true(входит)
             nTaxSumBaseN := nSumOut - nTaxSumN
           elseif tbL_ACZ .And. !tbL_NDS
           //TAX_SUM.TAX_BASE= MDOCM.SUMOUTR если MDOC. L_ACZ= true(входит) и MDOC. L_NDS=true(не входит)
             nTaxSumBaseN := nSumOut
           elseif !tbL_ACZ .And. !tbL_NDS
           //TAX_SUM.TAX_BASE= MDOCM.SUMOUTR + MDOCM.SUM_ACZ если MDOC. L_ACZ= true( не входит) и MDOC. L_NDS=true(не входит)
             nTaxSumBaseN := nSumOut + nTaxA  * ::mMultyStorno
           elseif !tbL_ACZ .And. tbL_NDS
           //TAX_SUM.TAX_BASE= MDOCM.SUMOUTR - MDOCM.SUM_NDS если MDOC. L_ACZ= false( не входит) и MDOC. L_NDS=true(входит) - это значит АКЦИЗА в модели склада НЕТ
             nTaxSumBaseN := nSumOut - nTaxSumN
           endif
         endif
         /*
         if tbL_NDS // в документе НДС в том числе
         //nBaseN := nSumOut - nTaxN
           if aModStr[i][_CALCRL] // Налог извлекатся
             nTaxSumBaseN := nBaseN * ::mMultyStorno + nTaxSumN
           else
             nTaxSumBaseN := nBaseN
           endif
         else //кроме того
         //nBaseN := nSumOut
           if aModStr[i][_CALCRL] // Налог извлекатся
             nTaxSumBaseN := nBaseN * ::mMultyStorno + nTaxSumN
           else
             nTaxSumBaseN := nBaseN
           endif
         endif
         */
         /*
         if !aModStr[i][_CALCRL] .And. !tbL_NDS // начисляется
           // соответствует налоговой модели С-Ф к сумму без налога + налог
           nTaxSumBaseN := nBaseN * ::mMultyStorno
         else //извлекается
            nTaxSumBaseN := nBaseN * ::mMultyStorno + nTaxSumN
         endif
          */
          /*
         if nPrior == 0
            nBaseS := nTaxSumBaseN
         endif
         */
         lYesNds := .T.
         nSumNDS := nTaxN * ::mMultyStorno
         /*
         if !(aModStr[i][_SUMUSE] == "2")
           nSumNNDS := nBaseN * ::mMultyStorno
           nSumA := (nBaseN + nTaxN) * ::mMultyStorno
         endif
         */
    endcase
 /*  //48804
    if aModStr[1][_SUMUSE] == "2"
      if tbL_NDS
        if !aModStr[i][_PRICEIN]
          nSumNNds := nSumNNds - mTax
        endif
      else
        nSumA := nSumA + mTax
        if aModStr[i][_PRICEIN]
          nSumNNds := nSumNNds + mTax
        endif
      endif

    else  //от стоимости
      if tbL_NDS
        if !aModStr[i][_CALCRL]
          nSumNNds := nSumNNds - mTax
        endif
      else
        nSumA := nSumA + mTax
        if aModStr[i][_CALCRL]
          nSumNNds := nSumNNds + mTax
        endif

      endif

    endif
  */

   // ::objModStr:MoveNext()
    nPrior := nPrior + 1
  next
  //enddo
  /*
  if aModStr[1][_SUMUSE] == "2"
    nSumA := nSumNNDS := nSumOut
    if !lYesNds
      nSumNDS := 0
    endif
    for i := 1 to len(aModStr)
      if Alltrim(aModStr[i][_SYSNUM]) == "2"
        if aModStr[i][_PRICEIN]
          nSumNNDS -= nSumNDS
        endif
      elseif Alltrim(aModStr[i][_SYSNUM]) == "1"
        if aModStr[i][_PRICEIN]
          nSumNNDS -= nTaxSumA
        endif
      endif
    next

  else
    if !lYesNds
      nSumA := nSumNNDS := nSumOut
      nSumNDS := 0
    endif
  endif
  */

  if !lYesNds
    nSumNDS := 0
  endif

  //48804
  if tbL_ACZ .And. tbL_NDS
  // TAX_STR.SUM_NNDS= MDOCM.SUMOUTR - MDOCM.SUM_NDS
  // если MDOC. L_ACZ =true(входит) и MDOC.L_NDS=true (входит)
    nSumNNDS := nSumOut - nSumNDS
  elseif tbL_ACZ .And. !tbL_NDS
  // TAX_STR.SUM_NNDS= MDOCM.SUMOUTR
  // если MDOC. L_ACZ =true(входит) MDOC. L_NDS=false ( не входит)
    nSumNNDS := nSumOut
  elseif !tbL_ACZ .And. !tbL_NDS
  // TAX_STR.SUM_NNDS= MDOCM.SUMOUTR + MDOCM.SUM_ACZ
  // если MDOC. L_ACZ =false( не входит) MDOC. L_NDS= false(не входит)
    nSumNNDS :=  nSumOut + nTaxSumA
  elseif !tbL_ACZ .And. tbL_NDS
  //TAX_STR.SUM_NNDS= MDOCM.SUMOUTR - MDOCM.SUM_NDS
  // если MDOC. L_ACZ =false(не входит) и MDOC. L_NDS=true(входит)  это значит акциза НЕТ
    nSumNNDS := nSumOut - nSumNDS
  endif
  nSumA := nSumNNDS + nSumNDS

  aRecSortSum[n][13] := nRateA
  aRecSortSum[n][14] := nTaxSumA
  aRecSortSum[n][15] := nTaxSumBaseA
  aRecSortSum[n][16] := nTaxSumBaseAN
  aRecSortSum[n][17] := nRateN
  aRecSortSum[n][18] := nTaxSumN
  aRecSortSum[n][19] := nTaxSumBaseN
  aRecSortSum[n][20] := nTaxSumBaseNN
  aRecSortSum[n][21] := nBaseS
  aRecSortSum[n][22] := nSumNNDS
  aRecSortSum[n][23] := nSumNDS
  aRecSortSum[n][24] := nSumA
  // цена приведенная к  налоговой модели nBaseS / aRecSortSum[n][6] - к-во
  //aRecSortSum[n][1] :=  aRecSortSum[n][1] +  str((nBaseS / aRecSortSum[n][6][1]),19,8) + str(nRateA,19,5) + str(nRateN,19,5) // добавляем в ключ - цену
 aRecSortSum[n][1] :=  aRecSortSum[n][1] +  str(nRateA,19,5) + str(nRateN,19,5) // добавляем в ключ налоги
 next

 if lGroup//::mGroupSf
   for n := 1 to len(aRec)
     AADD(a,arec[n])//ACopy(a,arec)
   next
   arec := {}
   for i := 1 to len(aRecSortSum)
     AADD(a,aRecSortSum[i])
   next
   if cStrType == "4"
     ASort(a,,,{|aX,aY|aX[1]  > aY[1] })
   else
     ASort(a,,,{|aX,aY|(aX[1] + aX[27]) > (aY[1] + aY[27])})//ASort(a)
   endif
   n:= 0
   cKey := ""
   for i:=1 to len(a)
    lExit := .F.
    if cKey == a[i][1]
         nVozvrat := 1
       //if aRec[n][6] <= 0 //  не от чего отнимать возвраты
         if (a[i][27] == "1" .AND. (::mAliasInv)->TI_CTG == "2") .Or. ;
            (a[i][27] == "2" .AND. (::mAliasInv)->TI_CTG == "1")
           nVozvrat := -1  // возвраты отнимаем
           if aRec[n][6][1] <= 0
             lExit := .T.
           endif
         endif
         if lExit
           Exit
         endif
         aRec[n][6][1] := aRec[n][6][1] + a[i][6][1] * nVozvrat
         aRec[n][6][2] := aRec[n][6][2] + a[i][6][2] * nVozvrat
         aRec[n][7] := aRec[n][7] + a[i][7] * nVozvrat
         aRec[n][8] := aRec[n][8] + a[i][8] * nVozvrat
         aRec[n][9] := aRec[n][9] + a[i][9] * nVozvrat
         aRec[n][31][1] := aRec[n][31][1] + a[i][31][1] * nVozvrat
         aRec[n][31][2] := aRec[n][31][2] + a[i][31][2] * nVozvrat
         aRec[n][32][1] := aRec[n][32][1] + a[i][32][1] * nVozvrat
         aRec[n][32][2] := aRec[n][32][2] + a[i][32][2] * nVozvrat
         for k := 1 to len(a[i][10])
            AADD(aRec[n][10],a[i][10][k])
         next
         aRec[n][14] := aRec[n][14] + a[i][14] * nVozvrat
         aRec[n][15] := aRec[n][15] + a[i][15] * nVozvrat
         aRec[n][16] := aRec[n][16] + a[i][16] * nVozvrat
         aRec[n][18] := aRec[n][18] + a[i][18] * nVozvrat
         aRec[n][19] := aRec[n][19] + a[i][19] * nVozvrat
         aRec[n][20] := aRec[n][20] + a[i][20] * nVozvrat
         aRec[n][21] := aRec[n][21] + a[i][21] * nVozvrat
         aRec[n][22] := aRec[n][22] + a[i][22] * nVozvrat
         aRec[n][23] := aRec[n][23] + a[i][23] * nVozvrat
         aRec[n][24] := aRec[n][24] + a[i][24] * nVozvrat
       //endif
    else
      if (::mAliasInv)->TI_CTG == "1"
         if a[i][27] == "1" .Or. cStrType == "4"// только документ возврата - его не обрабатываем
           AADD(aRec,a[i])
           cKey := a[i][1]
           n:= n +1
         endif
      else
         if a[i][27] == "2" .Or. cStrType == "4"// только документ возврата - его не обрабатываем
           AADD(aRec,a[i])
           cKey := a[i][1]
           n:= n +1
         endif
      endif
    endif
   next
 else
   for i := 1 to len(aRecSortSum)
     AADD(aRec,aRecSortSum[i])
   next
 endif
 _DbAreaClose(waGrup)
 recover using oErr
   _DbAreaClose(waGrup)
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.
////////////////////////////
//Регистрация корректировочных с-ф
/////////////////////////////
Method clsTax_Inv:CreateKorrRecInBook()
  local oErr,RecTp := ""
  local aParam,a := ::lNegativPozit() ,i
  local oObjBook,n := 0,cMsg
  if ::mParamIni[_TAX_QUE] == "2" .And. ::mlMsgForReg
    if a[1] .And. a[3] > 0
      n++
    endif

    if a[2] .And. a[4] > 0
      n++
    endif

    cMsg := "По счету-фактуре можно сформировать "
    if n == 2
       cMsg += "записи" + chr(13) + chr(10) + "в книгу покупок и в книгу продаж." + chr(13) + chr(10)
    elseif a[1]
      if ::TI_CTG == "1"
        cMsg += "запис в книгу покупок." + chr(13) + chr(10)
      else
        cMsg += "запис в книгу продаж." + chr(13) + chr(10)
      endif
    else
      if ::TI_CTG == "1"
        cMsg += "запис в книгу продаж." + chr(13) + chr(10)
      else
        cMsg += "запис в книгу покупок." + chr(13) + chr(10)
      endif
    endif

   cMsg += "Сформировать?"
   if !(messagebox(cMsg,TITLEAPP,36)== 6)
     ::mlReg := .F.
     Return .T.
   endif
  endif
  begin sequence
  for i := 1 to 2
    if !a[i] .Or. a[i+2] <= 0
      loop
    endif

    oObjBook := clsTax_Book():New()
    oObjBook:Open()
    if (::mAliasInv)->TI_CTG == "1"
      if i == 1
        aParam := {0,"1","ОП"}
      else
        aParam := {0,"2","ВС"}
      endif
    else
      if i == 1
        aParam := {0,"2","ОТ"}
      else
        aParam := {0,"1","ВЧ"}
      endif
    endif
    if !oObjBook:BeforeAppend(aParam)
      Break(.F.)
    endif
    if !oObjBook:Append()
      Break(.F.)
    endif
    oObjBook:SF_ID := (::mAliasInv)->DOC_ID
    if !oObjBook:Save()
    // Откроем форму книги
      if !StartFrmBook(oObjBook)
        oObjBook:Destroy()
      endif
    else
      oObjBook:Destroy()
    endif
    if ValType(oObjBook) == "O"
      oObjBook:Destroy()
    endif
    oObjBook := Nil
  next

  recover using oErr
   if ValType(oObjBook) == "O"
     oObjBook:Destroy()
   endif
   oObjBook := Nil
   if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.
////////////////////////
//PG
// для групповых записей делаем регистрацию в книгу продаж
///////////////////////
Method clsTax_Inv:CreateGroupRecInBook()
local  oErr,tb , cField := "" , cJrn
local i,j,n,cMsg := "",lDel := .T. , aDoc := {}
local cNameParam,RetValue,  nDoc := 0
 begin sequence
 if (::cWa)->Korr
   ::CreateKorrRecInBook()
   Break(.T.)
 endif
 /*
 if (!Empty((::cWa)->KORR) .And. !Empty((::cWa)->SFK_ID) ) ;
    .Or. ((::cWa)->DEF .And. !Empty(::mOldKorr) )
   ::CreateKorrRecInBook()
   Break(.T.)
 endif
 */
 if Len(::maTbDoc) < 1
   Break(.T.)
 endif


   //Проверим есть ли среди документов неудаленные
   for i := 1 to Len(::maTbDoc)
     cJrn := ::maTbDoc[i][1]
     if cJrn == "1701"
       cField := "DOC_ID"
     else
       cField := "NNOPER"
     endif
     if  Len(::maTbDoc[i][4]) > 0  .Or.  Len(::maTbDoc[i][3]) > 0
       if Len(::maTbDoc[i][4]) > 0
         aDoc := ::maTbDoc[i][4]
       else
         aDoc := ::maTbDoc[i][3]
       endif
       tb := ::maTbDoc[i][2]
       for j := 1 to Len(aDoc) // ходим по выбранным документам
         // Проверим а не удаленный ли документ
         (tb)->(DbGoTo(aDoc[j]))
         lDel := .F.
         for n := 1 to len(::aSfDoc)
           if ::aSfDoc[n][_DOCSTRID] == (tb)->&(cField)//NNOPER
             if !::aSfDoc[n][_DEL]
               //lDel := .T.
             //else
               nDoc++
             endif
           endif
         next
         //if !lDel
           //exit
         //endif
       next
     endif
   next
   if nDoc == 0//lDel
   // Все строки удаленные
     ::mlReg := .F.
     Break(.T.)
   endif
   // В зависимости от настройки - выдадим или нет
 // запрос на формирование записи в книгу
 if ::mParamIni[_TAX_QUE] == "2" .And. ::mlMsgForReg

   cMsg := "По счету-фактуре можно сформировать запись в книгу "
   if ::TI_CTG == "1"
    cMsg += "покупок." + chr(13) + chr(10)
   else
    cMsg += "продаж." + chr(13) + chr(10)
   endif
   cMsg += "Сформировать?"
   if !(messagebox(cMsg,TITLEAPP,36)== 6)
     ::mlReg := .F.
     Break(.T.)
   endif
 endif
 ::mlMsgForReg := .F.

  // не добавление документа в существующий с-ф
 if ::TI_CTG == "1"
   cNameParam := "IN_GR_BK"
 else
   cNameParam := "OUT_GR_BK"
 endif
 if GetTaxParamIni(cNameParam,@RetValue)
   if RetValue == "1"
      if Empty(::mnRecAddDoc)
        if nDoc  > 1
          ::CreateRecInBookWithoutDoc()
          Break(.T.)
        endif
      endif
    endif
 endif



 for i := 1 to Len(::maTbDoc)
   //if !(ValType(::maTbDoc[i][2]) == "O")
  //   Loop
   //endif
   cJrn := ::maTbDoc[i][1]
   if cJrn == "1701"
     cField := "DOC_ID"
   else
     cField := "NNOPER"
   endif
   if  Len(::maTbDoc[i][4]) > 0  .Or.  Len(::maTbDoc[i][3]) > 0
     if Len(::maTbDoc[i][4]) > 0
       aDoc := ::maTbDoc[i][4]
     else
       aDoc := ::maTbDoc[i][3]
     endif
     tb := ::maTbDoc[i][2]
     for j := 1 to Len(aDoc) // ходим по выбранным документам
       // Проверим а не удаленный ли документ
       (tb)->(DbGoTo(aDoc[j]))
       lDel := .F.
       for n := 1 to len(::aSfDoc)
         if ::aSfDoc[n][_DOCSTRID] == (tb)->&(cField)//NNOPER
           if ::aSfDoc[n][_DEL]
             lDel := .T.
           endif
         endif
       next
       if lDel
         loop
       endif

       if !Empty(::mnRecAddDoc)
         if ::maTbDoc[i][1] == ::mcJrnAddDoc .And. ;
            aDoc[j] == ::mnRecAddDoc

           //(tb)->(DbGoTo(::maTbDoc[i][4][j]))
           (tb)->(DbRUnLock(DbGoTo(aDoc[j])))
           ::DS:Skip(0)
           if ::SUM_A > ::SUM_BOOK
             if cJrn == "1701"
               ::CreateRecForGroupInBook(tb,cJrn)
             else
               //if ((tb)->KOP_NDS ==  ::KOP_NDS) .And. ;
               //   ((tb)->KOP_NNDS ==  ::KOP_NNDS) .And. ;
               //   ((tb)->KOP_NDS0 ==  ::KOP_NDS0) .And. ;
               //   ((tb)->KOP_AG_NDS ==  ::KOP_AG_NDS)
                 cJrn :=  ::maTbDoc[i][1]
                 if cJrn == "0901"
                   cJrn := (tb)->JRN_CODE
                 endif
                  ::CreateRecForGroupInBook(tb,cJrn)
               //endif
             endif
           else
             exit
           endif
         endif
       else
         //(tb)->(DbGoTo(::maTbDoc[i][4][j]))
         (tb)->(DbRUnLock(DbGoTo(aDoc[j])))
         ::DS:Skip(0)
         if ::SUM_A > ::SUM_BOOK
           if cJrn == "1701"
             ::CreateRecForGroupInBook(tb,cJrn)
           else
             //if ((tb)->KOP_NDS ==  ::KOP_NDS) .And. ;
             //   ((tb)->KOP_NNDS ==  ::KOP_NNDS) .And. ;
             //   ((tb)->KOP_NDS0 ==  ::KOP_NDS0) .And. ;
             //   ((tb)->KOP_AG_NDS ==  ::KOP_AG_NDS)
                 cJrn :=  ::maTbDoc[i][1]
                 if cJrn == "0901"
                   cJrn := (tb)->JRN_CODE
                 endif
                 ::CreateRecForGroupInBook(tb,cJrn)
             //endif
           endif
         else
           exit
         endif
       endif
     next
   endif
 next
 //::mlCreateRec := .T.
 recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

Method clsTax_Inv:CreateRecForGroupInBook(tb,nJrn)
local  oErr
local aParam //:= {0,"2","ОТ"}//,  SumRec := 0
local oObjBook, nId
 begin sequence
 //altd()
 do case
   case nJrn == "1701"
     nId := (tb)->DOC_ID
   case nJrn == "0301" //(::mAliasInv)->STR_TP2 //(::mAliasInv)->STR_TP == "2"
     //nJrn := "0301"
     nId := (tb)->NNOPER // tb:FieldValue("NNOPER")//::tbDoc:NNOPER
   case nJrn $ "0901,0904" //(::mAliasInv)->STR_TP3//(::mAliasInv)->STR_TP == "3"
     //nJrn := "0901"
     nId :=  (tb)->NNOPER //tb:FieldValue("NNOPER")//  ::tbDoc:NNOPER
   case nJrn == "TV01" .Or. nJrn == "0501"//(::mAliasInv)->STR_TP4 //(::mAliasInv)->STR_TP == "4"

     /*if (::mAliasInv)->TI_CTG == "1"
       nJrn := "TV01" // 1201
     else
       nJrn := "0501"
     endif
     */
     nId := (tb)->NNOPER // tb:FieldValue("NNOPER")//  ::tbDoc:NNOPER
 endcase
 oObjBook := clsTax_Book():New()
 oObjBook:Open()
 if (::mAliasInv)->TI_CTG == "1"
   aParam := {0,"1","ОП"}
 else
   aParam := {0,"2","ОТ"}
 endif
 if !oObjBook:BeforeAppend(aParam)
   Break(.F.)
 endif
 if !oObjBook:Append()
   Break(.F.)
 endif
 oObjBook:SF_ID := (::mAliasInv)->DOC_ID
 oObjBook:JRN_ID := nJrn
 oObjBook:SRC_ID := nId //iif(ValType(::mParams[1][i])=="N",Str(::mParams[1][i]),::mParams[1][i])
 if !oObjBook:Save()
 // Откроем форму книги
   if !StartFrmBook(oObjBook)
     oObjBook:Destroy()
   endif
 else
   oObjBook:Destroy()
 endif
 if ValType(oObjBook) == "O"
   oObjBook:Destroy()
 endif
 oObjBook := Nil

 recover using oErr
  if ValType(oObjBook) == "O"
    oObjBook:Destroy()
  endif
  oObjBook := Nil
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.


///////////////////////////
//PG
// возвращает адресс  по идентификатору записи в справчнике адресов
// lEnt Т - собственное предприятие иначе партнер
//////////////////////
Method clsTax_Inv:GetAddrName(lEnt)
Local s := Space(160),cKey
 begin sequence
 if lEnt
   cKey := (::mAliasInv)->ENT_LOC
 else
   cKey := (::mAliasInv)->PRT_LOC
 endif
 if Empty(cKey)
   Break
 endif
 if !(ValType(::mTbPartAddr) == "O")
    ::mTbPartAddr := CreateDbRecord(B6_DBF_PATH + "prt_addr.DBF")
 endif

 if ::mTbPartAddr:Seek(cKey,.T.,"TAG_ID")
   s := ::mTbPartAddr:FieldValue("address")
 endif

 end sequence
Return s

/////////////////////
//PG
//Создает рекордсет записей связанных со С_Ф документов
// и заполняет массив maDoc - RecNo этих документов
////////////////////
Method clsTax_Inv:CreateDocument(lNoLock)
local  oErr,cIdSf
local i,nJrn,k,cIdStr,n,m//,cIdDoc,,j,nRec
//Local dbSfDoc := ::SFDOC:DS
//Local cAl := dbSfDoc:Alias()
local nRecNo := ::TAX_STR:RecNo()
local cStrTp := ""
local l101 := .F.,l201 := .F., l301 := .F.
Local l501 := .F., l901 := .F.,l1201 := .F.,l1701 := .F.
Local lPM01 := .F.,lPM02 := .F.
local n301,n501,n901,n1701
local cAlias,cKey,aDoc := {}, lZac := .F.
 begin sequence
 if !(ValType(lNoLock) == "L")
   lNoLock := .F.
 endif
 for i := 1 to len(::maTbDoc)
    _DbAreaClose(::maTbDoc[i][2])
    _DbAreaClose(::maTbDoc[i][5])
 next
 ::aSFDOC := {}
 ::maTbDoc := {}
  cIdSf := ::DS:FieldValue("DOC_ID")
 // Для авансовых с-ф - тип строки может быть отличный от 0 и 1
 // для них свое заполнение документов
 if ::IsRBook(@lZac)  .And. lZac
   for k := 1 to 4
     if k == 1
       nJrn := "0101"
       m := 1
     elseif k == 2
       nJrn := "0201"
       m := 2
     elseif k == 3
       nJrn := "PM01"
       m := 7
     elseif k == 4
       nJrn := "PM02"
       m := 8
     endif
     if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[m][1], @cAlias,::aTab[m][3])
        Break(.F.)
     endif
     if (cAlias)->(DbSeek(cIdSf)) .And. ;
        (!(nJrn $ "PM01,PM02") ;
         .Or. ((nJrn == "PM01") .And. (cAlias)->FIN_CTG="1");
         .Or. ((nJrn == "PM02") .And. (cAlias)->FIN_CTG="2"))

       AADD(::maTbDoc,{nJrn,,{},{},})
       i := Len(::maTbDoc)
       ::maTbDoc[i][2] := cAlias
       do while (cAlias)->SF_ID == cIdSf
         if k == 1
           cKey := "0101"+(cAlias)->NNOPER_ID+"0"
           AADD(::aSFDOC,{cIdSf,(::mAliasStr)->STR_ID,(cAlias)->NNOPER_ID,(cAlias)->NNOPER_ID,"0101",.F.,0,cKey,(cAlias)->(RecNo())})
         elseif k == 2
           cKey := "0201"+(cAlias)->NNOPER+"0"
           AADD(::aSFDOC,{cIdSf,(::mAliasStr)->STR_ID,(cAlias)->NNOPER,(cAlias)->NNOPER,"0201",.F.,0,cKey,(cAlias)->(RecNo())})
         elseif k == 3
           cKey := "PM01"+(cAlias)->RowId+"0"
           AADD(::aSFDOC,{cIdSf,(::mAliasStr)->STR_ID,(cAlias)->RowId,(cAlias)->RowId,"PM01",.F.,0,cKey,(cAlias)->(RecNo())})
         elseif k == 4
           cKey := "PM02"+(cAlias)->RowId+"0"
           AADD(::aSFDOC,{cIdSf,(::mAliasStr)->STR_ID,(cAlias)->RowId,(cAlias)->RowId,"PM02",.F.,0,cKey,(cAlias)->(RecNo())})
         endif

         if !lNoLock
           if (cAlias)->(DbRLock((cAlias)->(RecNo())))
            //Массив документов с которыми стартовали
             AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
           else
             Break(.F.)
           endif
         else
           AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
         endif
         (cAlias)->(DbSkip(1))
       enddo
     else
        _DbAreaClose(cAlias)
     endif
     if Len(::aSFDOC) > 0
       ::mlYesDoc := .T.
       exit
     endif
   next

   Break(.T.)
 endif

  (::mAliasStr)->(DbGoTop())
  Do While !(::mAliasStr)->(Eof())
    if (::mAliasStr)->STR_SRC
      cStrTp := (::mAliasStr)->STR_TP
      Do case
        case cStrTp == "0"
          //
          // Проверим сначала в новой подсистеме потом в старой
          if CheckSubSystem("BD")
            nJrn := "PM01"
            k := 7
            if !lPM01
              if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][1], @cAlias,::aTab[k][3])
                Break(.F.)
              endif
              if (cAlias)->(DbSeek(cIdSf))
              //Документы без строк ищем только по идентификатору с-ф
                lPM01 := .T.
                // журнал, ро документа, м-в д-тов до, м-в добав, ро строк
                AADD(::maTbDoc,{nJrn,,{},{},})
                i := Len(::maTbDoc)
                ::maTbDoc[i][2] := cAlias
                do while (cAlias)->SF_ID == cIdSf
                  cKey := "PM01"+(cAlias)->ROWID+"0"
                  AADD(::aSFDOC,{cIdSf,(::mAliasStr)->STR_ID,(cAlias)->ROWID,(cAlias)->ROWID,"PM01",.F.,0,cKey,(cAlias)->(RecNo())})
                  if !lNoLock
                    if (cAlias)->(DbRLock((cAlias)->(RecNo())))
                      //Массив документов с которыми стартовали
                      AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
                    else
                      Break(.F.)
                    endif
                  else
                    AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
                  endif
                  (cAlias)->(DbSkip(1))
                enddo
              else
                _DbAreaClose(cAlias)
              endif
            endif
          endif

          if !lPM01
            nJrn := "0101"
            k := 1
            if !l101
              // Документы без строк ищем только по идентификатору с-ф
               l101 := .T.

               if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][1], @cAlias,::aTab[k][3])
                 Break(.F.)
               endif
               if (cAlias)->(DbSeek(cIdSf))
                 AADD(::maTbDoc,{nJrn,,{},{},})
                 i := Len(::maTbDoc)
                 ::maTbDoc[i][2] := cAlias
                 do while (cAlias)->SF_ID == cIdSf
                   cKey := "0101"+(cAlias)->NNOPER_ID+"0"
                   AADD(::aSFDOC,{cIdSf,(::mAliasStr)->STR_ID,(cAlias)->NNOPER_ID,(cAlias)->NNOPER_ID,"0101",.F.,0,cKey,(cAlias)->(RecNo())})
                   if !lNoLock
                     if (cAlias)->(DbRLock((cAlias)->(RecNo())))
                       //Массив документов с которыми стартовали
                         AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
                     else
                        Break(.F.)
                     endif
                   else
                     AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
                   endif
                   (cAlias)->(DbSkip(1))
                 enddo
               else
                 _DbAreaClose(cAlias)
               endif
            endif
          endif

        case cStrTp == "1"
          if CheckSubSystem("ND")
            nJrn := "PM02"
            k := 8
            if !lPM02
              if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][1], @cAlias,::aTab[k][3])
                Break(.F.)
              endif
              if (cAlias)->(DbSeek(cIdSf))
                lPM02 := .T.
                // журнал, ро документа, м-в д-тов до, м-в добав, ро строк
                AADD(::maTbDoc,{nJrn,,{},{},})
                i := Len(::maTbDoc)
                ::maTbDoc[i][2] := cAlias
                do while (cAlias)->SF_ID == cIdSf
                  cKey := "PM02"+(cAlias)->ROWID+"0"
                  AADD(::aSFDOC,{cIdSf,(::mAliasStr)->STR_ID,(cAlias)->ROWID,(cAlias)->ROWID,"PM02",.F.,0,cKey,(cAlias)->(RecNo())})
                  if !lNoLock
                    if (cAlias)->(DbRLock((cAlias)->(RecNo())))
                    //Массив документов с которыми стартовали
                      AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
                    else
                      Break(.F.)
                    endif
                  else
                    AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
                  endif
                  (cAlias)->(DbSkip(1))
                enddo
              else
                _DbAreaClose(cAlias)
              endif
            endif
          endif

          if !lPM02
            nJrn := "0201"
            k := 2
            if !l201
              l201 := .T.
              // журнал, ро документа, м-в д-тов до, м-в добав, ро строк

              if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][1], @cAlias,::aTab[k][3])
                Break(.F.)
              endif

              if (cAlias)->(DbSeek(cIdSf))
                AADD(::maTbDoc,{nJrn,,{},{},})
                i := Len(::maTbDoc)
                ::maTbDoc[i][2] := cAlias
                do while (cAlias)->SF_ID == cIdSf
                  cKey := "0201"+(cAlias)->NNOPER+"0"
                  AADD(::aSFDOC,{cIdSf,(::mAliasStr)->STR_ID,(cAlias)->NNOPER,(cAlias)->NNOPER,"0201",.F.,0,cKey,(cAlias)->(RecNo())})
                  if !lNoLock
                    if (cAlias)->(DbRLock((cAlias)->(RecNo())))
                    //Массив документов с которыми стартовали
                      AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
                    else
                      Break(.F.)
                    endif
                  else
                    AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
                  endif
                  (cAlias)->(DbSkip(1))
                enddo
              else
                  _DbAreaClose(cAlias)
              endif
            endif
          endif
          /*
          if CheckSubSystem("PM")
          nJrn := "PM02"
            k := 8
            if !lPM02
            // Документы без строк ищем только по идентификатору с-ф
              lPM02 := .T.
              // журнал, ро документа, м-в д-тов до, м-в добав, ро строк
              AADD(::maTbDoc,{nJrn,,{},{},})
              i := Len(::maTbDoc)
              if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][1], @cAlias,::aTab[k][3])
                 Break(.F.)
              endif
              ::maTbDoc[i][2] := cAlias
              if (cAlias)->(DbSeek(cIdSf))
                do while (cAlias)->SF_ID == cIdSf
                  cKey := "PM02"+(cAlias)->ROWID+"0"
                  AADD(::aSFDOC,{cIdSf,(::mAliasStr)->STR_ID,(cAlias)->ROWID,(cAlias)->ROWID,"PM02",.F.,0,cKey,(cAlias)->(RecNo())})
                  if !lNoLock
                    if (cAlias)->(DbRLock((cAlias)->(RecNo())))
                      //Массив документов с которыми стартовали
                        AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
                    else
                       Break(.F.)
                    endif
                  endif
                  (cAlias)->(DbSkip(1))
                enddo
              endif
            endif
          else
            nJrn := "0201"
            //  nJrn := 201
            k := 2
            if !l201
              l201 := .T.
              // журнал, ро документа, м-в д-тов до, м-в добав, ро строк
              AADD(::maTbDoc,{nJrn,,{},{},})
              i := Len(::maTbDoc)
              if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][1], @cAlias,::aTab[k][3])
                 Break(.F.)
              endif
              ::maTbDoc[i][2] := cAlias
              if (cAlias)->(DbSeek(cIdSf))
                do while (cAlias)->SF_ID == cIdSf
                  cKey := "0201"+(cAlias)->NNOPER+"0"
                  AADD(::aSFDOC,{cIdSf,(::mAliasStr)->STR_ID,(cAlias)->NNOPER,(cAlias)->NNOPER,"0201",.F.,0,cKey,(cAlias)->(RecNo())})
                  if !lNoLock
                    if (cAlias)->(DbRLock((cAlias)->(RecNo())))
                      //Массив документов с которыми стартовали
                        AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
                     else
                       Break(.F.)
                     endif
                   endif
                  (cAlias)->(DbSkip(1))
                enddo
              else
              //
              //  if (::mAliasStr)->(DbRLock((::mAliasStr)->(RecNo())))
              //    (::mAliasStr)->STR_SRC := .F.
              //    (::mAliasStr)->(DbRUnLock((::mAliasStr)->(RecNo())) )
              //  endif
              //
              endif
            endif
          endif
          */
        case cStrTp == "2"
          nJrn := "0301"
          k := 3
          if !l301
            l301 := .T.
            // журнал, ро документа, м-в д-тов до, м-в добав, ро строк
            AADD(::maTbDoc,{nJrn,,{},{},})
            i := Len(::maTbDoc)
            if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][1], @cAlias,::aTab[k][3])
               Break(.F.)
            endif
            ::maTbDoc[i][2] := cAlias
            if (cAlias)->(DbSeek(cIdSf))
              do while (cAlias)->OPER_FACT == cIdSf
                cKey := "0301"+(cAlias)->NNOPER+"0"
                AADD(::aSFDOC,{cIdSf,cIdSf,(cAlias)->NNOPER,(cAlias)->NNOPER,"0301",.F.,0,cKey,(cAlias)->(RecNo())})
                if !lNoLock
                  if (cAlias)->(DbRLock((cAlias)->(RecNo())))
                   //Массив документов с которыми стартовали
                     AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
                  else
                    Break(.F.)
                  endif
                else
                  AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
                endif
               (cAlias)->(DbSkip(1))
              enddo
            else
            /*
              if (::mAliasStr)->(DbRLock((::mAliasStr)->(RecNo())))
                (::mAliasStr)->STR_SRC := .F.
                (::mAliasStr)->(DbRUnLock((::mAliasStr)->(RecNo())))
              endif
              */
            endif
            if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][6], @cAlias,::aTab[k][7])
               Break(.F.)
            endif
            ::maTbDoc[i][5] := cAlias
            n301 := i
          endif
          n := len(::maTbDoc[n301][3])
          if n > 0
            cAlias := (::maTbDoc[n301][5])
            (::maTbDoc[i][2])->(OrdSetFocus(::aTab[k][2]))
            cIdStr := (::mAliasStr)->STR_ID
            if (cAlias)->(DbSeek(cIdStr))
              do while (cAlias)->OPER_FACT == cIdStr
                if (::maTbDoc[i][2])->(DbSeek((cAlias)->NNOPER_))
                //Если сбойнула отметка шапки -  строки отметили - шапку нет
                  if (::maTbDoc[i][2])->OPER_FACT == cIdSf
                    cKey := "0301"+(::maTbDoc[n301][5])->NNOPER_+"1"
                    AADD(::aSFDOC,{cIdSf,cIdStr,(::maTbDoc[n301][5])->NNOPER_,(::maTbDoc[n301][5])->NNOPERM,"0301",.F.,0,cKey})
                  endif
                endif
                (cAlias)->(DbSkip(1))
              enddo
            else
            /*
              if (::mAliasStr)->(DbRLock((::mAliasStr)->(RecNo())))
                (::mAliasStr)->STR_SRC := .F.
                (::mAliasStr)->(DbRUnLock((::mAliasStr)->(RecNo())))
              endif
              */
            endif
          endif
        case cStrTp == "3"
          nJrn := "0901"
          k := 4
          if !l901
            l901 := .T.
            // журнал, ро документа, м-в д-тов до, м-в добав, ро строк
            AADD(::maTbDoc,{nJrn,,{},{},})
            i := Len(::maTbDoc)
            if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][1], @cAlias,::aTab[k][3])
               Break(.F.)
            endif
            ::maTbDoc[i][2] := cAlias
            if (cAlias)->(DbSeek(cIdSf))
              do while (cAlias)->OPER_FACT == cIdSf
                 cKey := "0901"+(cAlias)->NNOPER+"0"
                 AADD(::aSFDOC,{cIdSf,cIdSf,(cAlias)->NNOPER,(cAlias)->NNOPER,"0901",.F.,0,cKey,(cAlias)->(RecNo())})
                 if !lNoLock
                   if (cAlias)->(DbRLock((cAlias)->(RecNo())))
                    //Массив документов с которыми стартовали
                      AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
                   else
                     Break(.F.)
                   endif
                 else
                   AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
                 endif
                (cAlias)->(DbSkip(1))
              enddo
            else
            /*
              if (::mAliasStr)->(DbRLock((::mAliasStr)->(RecNo())))
                (::mAliasStr)->STR_SRC := .F.
                (::mAliasStr)->(DbRUnLock((::mAliasStr)->(RecNo())))
              endif
              */
            endif
            if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][6], @cAlias,::aTab[k][7])
               Break(.F.)
            endif
            ::maTbDoc[i][5] := cAlias
            n901 := i
          endif
          n := len(::maTbDoc[n901][3])
          if n > 0
            cAlias := (::maTbDoc[n901][5])
            (::maTbDoc[i][2])->(OrdSetFocus(::aTab[k][2]))
            cIdStr := (::mAliasStr)->STR_ID
            if (cAlias)->(DbSeek(cIdStr))
              do while (cAlias)->OPER_FACT == cIdStr
                if (::maTbDoc[i][2])->(DbSeek((cAlias)->NNOPER_))
                //Если сбойнула отметка шапки -  строки отметили - шапку нет
                  if (::maTbDoc[i][2])->OPER_FACT == cIdSf
                    cKey := "0901"+(::maTbDoc[n901][5])->NNOPER_+"1"
                    AADD(::aSFDOC,{cIdSf,cIdStr,(::maTbDoc[n901][5])->NNOPER_,(::maTbDoc[n901][5])->NNOPERM,"0901",.F.,0,cKey})
                  endif
                endif
                (cAlias)->(DbSkip(1))
              enddo
            else
            /*
              if (::mAliasStr)->(DbRLock((::mAliasStr)->(RecNo())))
                (::mAliasStr)->STR_SRC := .F.
                (::mAliasStr)->(DbRUnLock((::mAliasStr)->(RecNo())))
              endif
              */
            endif
          endif
        case cStrTp == "4"
          if (::mAliasInv)->TI_CTG == "1"
            nJrn := "TV01"//1201
             k := 5
          else
            nJrn := "0501"
             k := 6
          endif
          if !l501
            l501 := .T.
            // журнал, ро документа, м-в д-тов до, м-в добав, ро строк
            AADD(::maTbDoc,{nJrn,,{},{},})
            i := Len(::maTbDoc)
            if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][1], @cAlias,::aTab[k][3])
               Break(.F.)
            endif
            ::maTbDoc[i][2] := cAlias
            if (cAlias)->(DbSeek(cIdSf))
              do while (cAlias)->OPER_FACT == cIdSf
                 cKey := nJrn+(cAlias)->NNOPER+"0"
                 AADD(::aSFDOC,{cIdSf,cIdSf,(cAlias)->NNOPER,(cAlias)->NNOPER,nJrn,.F.,0,cKey,(cAlias)->(RecNo())})
                 if !lNoLock
                   if (cAlias)->(DbRLock((cAlias)->(RecNo())))
                    //Массив документов с которыми стартовали
                      AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
                   else
                     Break(.F.)
                   endif
                 else
                   AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
                 endif
                (cAlias)->(DbSkip(1))
              enddo
            else
            /*
              if (::mAliasStr)->(DbRLock((::mAliasStr)->(RecNo())))
                (::mAliasStr)->STR_SRC := .F.
                (::mAliasStr)->(DbRUnLock((::mAliasStr)->(RecNo())))
              endif
              */
            endif
            if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][6], @cAlias,::aTab[k][7])
               Break(.F.)
            endif
            ::maTbDoc[i][5] := cAlias
            n501 := i
          endif
          n := len(::maTbDoc[n501][3])
          if n > 0
            cAlias := (::maTbDoc[n501][5])
            (::maTbDoc[i][2])->(OrdSetFocus(::aTab[k][2]))
            cIdStr := (::mAliasStr)->STR_ID
            if (cAlias)->(DbSeek(cIdStr))
              do while (cAlias)->OPER_FACT == cIdStr
                if (::maTbDoc[i][2])->(DbSeek((cAlias)->NNOPER_))
                //Если сбойнула отметка шапки -  строки отметили - шапку нет
                  if (::maTbDoc[i][2])->OPER_FACT == cIdSf
                    cKey := nJrn+(::maTbDoc[n501][5])->NNOPER_+"1"
                    AADD(::aSFDOC,{cIdSf,cIdStr,(::maTbDoc[n501][5])->NNOPER_,(::maTbDoc[n501][5])->NNOPER,nJrn,.F.,0,cKey})
                  endif
                endif
                (cAlias)->(DbSkip(1))
              enddo
            else
            /*
              if (::mAliasStr)->(DbRLock((::mAliasStr)->(RecNo())))
                (::mAliasStr)->STR_SRC := .F.
                (::mAliasStr)->(DbRUnLock((::mAliasStr)->(RecNo())))
              endif
              */
            endif
          endif

        case cStrTp == "5"
          nJrn := "1701"
          k := 9
          if !l1701
            l1701 := .T.
            // журнал, ро документа, м-в д-тов до, м-в добав, ро строк
            AADD(::maTbDoc,{nJrn,,{},{},})
            i := Len(::maTbDoc)
            if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][1], @cAlias,::aTab[k][3])
               Break(.F.)
            endif
            ::maTbDoc[i][2] := cAlias
            if (cAlias)->(DbSeek(cIdSf))
              do while (cAlias)->SRC_ID == cIdSf
                 cKey := "1701"+(cAlias)->DOC_ID+"0"
                 AADD(::aSFDOC,{cIdSf,cIdSf,(cAlias)->DOC_ID,(cAlias)->DOC_ID,"1701",.F.,0,cKey,(cAlias)->(RecNo())})
                 if !lNoLock
                   if (cAlias)->(DbRLock((cAlias)->(RecNo())))
                    //Массив документов с которыми стартовали
                      AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
                   else
                     Break(.F.)
                   endif
                 else
                   AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
                 endif
                (cAlias)->(DbSkip(1))
              enddo
            else

            endif
            if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][6], @cAlias,::aTab[k][7])
               Break(.F.)
            endif
            ::maTbDoc[i][5] := cAlias
            n1701 := i
          endif
          n := len(::maTbDoc[n1701][3])
          if n > 0
            cAlias := (::maTbDoc[n1701][5])
            (::maTbDoc[i][2])->(OrdSetFocus(::aTab[k][2]))
            cIdStr := (::mAliasStr)->STR_ID
            if (cAlias)->(DbSeek(cIdStr))
              do while (cAlias)->SSRC_ID == cIdStr
                if (::maTbDoc[i][2])->(DbSeek((cAlias)->DOC_ID))
                //Если сбойнула отметка шапки -  строки отметили - шапку нет
                  if (::maTbDoc[i][2])->SRC_ID == cIdSf
                    cKey := "1701"+(::maTbDoc[n1701][5])->DOC_ID+"1"
                    AADD(::aSFDOC,{cIdSf,cIdStr,(::maTbDoc[n1701][5])->DOC_ID,(::maTbDoc[n1701][5])->STR_ID,"1701",.F.,0,cKey})
                  endif
                endif
                (cAlias)->(DbSkip(1))
              enddo
            else

            endif
          endif
      endcase
    endif
    (::mAliasStr)->(DbSkip(1))
  enddo
    /*
  //
  cIdSf := ::DS:FieldValue("DOC_ID")
  (::mAliasStr)->(DbGoTop())
  Do While !(::mAliasStr)->(Eof())
  // Если строка создана по д-ту запишем в массив связку с-ф д-т

    if (::mAliasStr)->STR_SRC
      cStrTp := (::mAliasStr)->STR_TP
      Do case
        case cStrTp == "0"
          nJrn := 101
          k := 1
          if !l101
            l101 := .T.
            // журнал, ро документа, м-в д-тов до, м-в добав, ро строк
            AADD(::maTbDoc,{nJrn,,{},{},})
            i := Len(::maTbDoc)
            if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][1], @cAlias,::aTab[k][3])
               Break(.F.)
            endif
            ::maTbDoc[i][2] := cAlias
            (cAlias)->(DbSeek(cIdSf))
            do while (cAlias)->SF_ID == cIdSf
              cKey := Str(101,4,0)+(cAlias)->NNOPER_ID+"1"
              AADD(::aSFDOC,{cIdSf,(::mAliasStr)->STR_ID,(cAlias)->NNOPER_ID,(cAlias)->NNOPER_ID,101,.F.,0,cKey,(cAlias)->(RecNo())})
              if (cAlias)->(DbRLock((cAlias)->(RecNo())))
                //Массив документов с которыми стартовали
                  AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
              else
                 Break(.F.)
              endif
              (cAlias)->(DbSkip(1))
            enddo

          endif
        case cStrTp == "1"
          nJrn := 201
          k := 2
          if !l101
            l101 := .T.
            // журнал, ро документа, м-в д-тов до, м-в добав, ро строк
            AADD(::maTbDoc,{nJrn,,{},{},})
            i := Len(::maTbDoc)
            if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][1], @cAlias,::aTab[k][3])
               Break(.F.)
            endif
            ::maTbDoc[i][2] := cAlias
            (cAlias)->(DbSeek(cIdSf))
            do while (cAlias)->SF_ID == cIdSf
              cKey := Str(201,4,0)+(cAlias)->NNOPER+"1"
              AADD(::aSFDOC,{cIdSf,(::mAliasStr)->STR_ID,(cAlias)->NNOPER,(cAlias)->NNOPER,201,.F.,0,cKey,(cAlias)->(RecNo())})
              if (cAlias)->(DbRLock((cAlias)->(RecNo())))
                //Массив документов с которыми стартовали
                  AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
               else
                 Break(.F.)
               endif
              (cAlias)->(DbSkip(1))
            enddo
          endif
        case cStrTp == "2"
          nJrn := 301
          k := 3
          if !l301
            l301 := .T.
            // журнал, ро документа, м-в д-тов до, м-в добав, ро строк
            AADD(::maTbDoc,{nJrn,,{},{},})
            i := Len(::maTbDoc)
            if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][1], @cAlias,::aTab[k][3])
               Break(.F.)
            endif
            ::maTbDoc[i][2] := cAlias
            (cAlias)->(DbSeek(cIdSf))
            do while (cAlias)->OPER_FACT == cIdSf
               cKey := Str(301,4,0)+(cAlias)->NNOPER+"1"
               AADD(::aSFDOC,{cIdSf,cIdSf,(cAlias)->NNOPER,(cAlias)->NNOPER,301,.F.,0,cKey,(cAlias)->(RecNo())})
               if (cAlias)->(DbRLock((cAlias)->(RecNo())))
                //Массив документов с которыми стартовали
                  AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
               else
                 Break(.F.)
               endif
              (cAlias)->(DbSkip(1))
            enddo
            if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][6], @cAlias,::aTab[k][7])
               Break(.F.)
            endif
            ::maTbDoc[i][5] := cAlias
            n301 := i
          endif
          cIdStr := (::mAliasStr)->STR_ID
          (::maTbDoc[n301][5])->(DbSeek(cIdStr))
          do while (cAlias)->OPER_FACT == cIdStr
            cKey := Str(301,4,0)+(::maTbDoc[n301][5])->NNOPER_+"0"
            AADD(::aSFDOC,{cIdSf,cIdStr,(::maTbDoc[n301][5])->NNOPER_,(::maTbDoc[n301][5])->NNOPERM,301,.F.,0,cKey})
           (cAlias)->(DbSkip(1))
          enddo
        case cStrTp == "3"
          nJrn := 901
          k := 4
          if !l901
            l901 := .T.
            // журнал, ро документа, м-в д-тов до, м-в добав, ро строк
            AADD(::maTbDoc,{nJrn,,{},{},})
            i := Len(::maTbDoc)
            if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][1], @cAlias,::aTab[k][3])
               Break(.F.)
            endif
            ::maTbDoc[i][2] := cAlias
            (cAlias)->(DbSeek(cIdSf))
            do while (cAlias)->OPER_FACT == cIdSf
              cKey := Str(901,4,0)+(cAlias)->NNOPER+"1"
              AADD(::aSFDOC,{cIdSf,cIdSf,(cAlias)->NNOPER,(cAlias)->NNOPER,901,.F.,0,cKey,(cAlias)->(RecNo())})
              if (cAlias)->(DbRLock((cAlias)->(RecNo())))
                //Массив документов с которыми стартовали
                  AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
               else
                 Break(.F.)
               endif
              (cAlias)->(DbSkip(1))
            enddo
            if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][6], @cAlias,::aTab[k][7])
               Break(.F.)
            endif
            ::maTbDoc[i][5] := cAlias
            n901 := i
          endif
          cIdStr := (::mAliasStr)->STR_ID
          (::maTbDoc[n901][5])->(DbSeek(cIdStr))
          do while (cAlias)->OPER_FACT == cIdStr
            cKey := Str(901,4,0)+(::maTbDoc[n901][5])->NNOPER_+"0"
            AADD(::aSFDOC,{cIdSf,cIdStr,(::maTbDoc[n901][5])->NNOPER_,(::maTbDoc[n901][5])->NNOPERM,901,.F.,0,cKey})
           (cAlias)->(DbSkip(1))
          enddo
        case cStrTp == "4"
          nJrn := 1201
          k := 5
          if !l1201
            l1201 := .T.
            // журнал, ро документа, м-в д-тов до, м-в добав, ро строк
            AADD(::maTbDoc,{nJrn,,{},{},})
            i := Len(::maTbDoc)
            if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][1], @cAlias,::aTab[k][3])
               Break(.F.)
            endif
            ::maTbDoc[i][2] := cAlias
            (cAlias)->(DbSeek(cIdSf))
            do while (cAlias)->OPER_FACT == cIdSf
              cKey := Str(1201,4,0)+(cAlias)->NNOPER+"1"
              AADD(::aSFDOC,{cIdSf,cIdSf,(cAlias)->NNOPER,(cAlias)->NNOPER,1201,.F.,0,cKey,(cAlias)->(RecNo())})
              if (cAlias)->(DbRLock((cAlias)->(RecNo())))
                //Массив документов с которыми стартовали
                  AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
               else
                 Break(.F.)
               endif
              (cAlias)->(DbSkip(1))
            enddo
            if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][6], @cAlias,::aTab[k][7])
               Break(.F.)
            endif
            ::maTbDoc[i][5] := cAlias
            n1201 := i
          endif
          cIdStr := (::mAliasStr)->STR_ID
          (::maTbDoc[n1201][5])->(DbSeek(cIdStr))
          do while (cAlias)->OPER_FACT == cIdStr
            cKey := Str(1201,4,0)+(::maTbDoc[n1201][5])->NNOPER_+"0"
            AADD(::aSFDOC,{cIdSf,cIdStr,(::maTbDoc[n1201][5])->NNOPER_,(::maTbDoc[n1201][5])->NNOPER,1201,.F.,0,cKey})
           (cAlias)->(DbSkip(1))
          enddo
        case cStrTp == "5"
          nJrn := 501
          k := 6
          if !l501
            l501 := .T.
            // журнал, ро документа, м-в д-тов до, м-в добав, ро строк
            AADD(::maTbDoc,{nJrn,,{},{},})
            i := Len(::maTbDoc)
            if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][1], @cAlias,::aTab[k][3])
               Break(.F.)
            endif
            ::maTbDoc[i][2] := cAlias
            (cAlias)->(DbSeek(cIdSf))
            do while (cAlias)->OPER_FACT == cIdSf
              cKey := Str(501,4,0)+(cAlias)->NNOPER+"1"
              AADD(::aSFDOC,{cIdSf,cIdSf,(cAlias)->NNOPER,(cAlias)->NNOPER,501,.F.,0,cKey,(cAlias)->(RecNo())})
              if (cAlias)->(DbRLock((cAlias)->(RecNo())))
                //Массив документов с которыми стартовали
                  AADD(::maTbDoc[i][3],(cAlias)->(RecNo()) )
               else
                 Break(.F.)
               endif
              (cAlias)->(DbSkip(1))
            enddo
            if ! _DbAreaOpen(B6_DBF_PATH + ::aTab[k][6], @cAlias,::aTab[k][7])
               Break(.F.)
            endif
            ::maTbDoc[i][5] := cAlias
            n501 := i
          endif
          cIdStr := (::mAliasStr)->STR_ID
          (::maTbDoc[n501][5])->(DbSeek(cIdStr))
          do while (cAlias)->OPER_FACT == cIdStr
            cKey := Str(501,4,0)+(::maTbDoc[n501][5])->NNOPER_+"0"
            AADD(::aSFDOC,{cIdSf,cIdStr,(::maTbDoc[n501][5])->NNOPER_,(::maTbDoc[n501][5])->NNOPER,501,.F.,0,cKey})
           (cAlias)->(DbSkip(1))
          enddo
      endcase
    endif
    (::mAliasStr)->(DbSkip(1))
  enddo
  */
  (::mAliasStr)->(DbGoTo(nRecNo))
  if Len(::aSFDOC) > 0
    ::mlYesDoc := .T.
  endif
  /*
  dbSfDoc:SetOrder("TAG_SFDOC")
  dbSfDoc:Scope(cIdSf,cIdSf,"TAG_SFDOC")
  dbSfDoc:GoTop()
  Do While !dbSfDoc:Eof()
    AADD(::maOldSfDoc,dbSfDoc:RecNo())
    nJrn := (cAl)->Jrn_Id
    k := 0
    for j := 1 to len(::aTab)
      if nJrn == ::aTab[j][5]
        k := j
        exit
      endif
    next
    //k := AScan(::aTab,nJrn)
    cIdDoc := (cAl)->Doc_Id
    cIdStr := (cAl)->DocStr_Id
    if !(cIdDoc == cIdStr)
    // Пропускаем регистрацию строк
      dbSfDoc:Skip(1)
      Loop
    endif
    //n := AScan(::maTbDoc,nJrn)
    n := 0
    for j := 1 to len(::maTbDoc)
      if nJrn == ::maTbDoc[j][1]
        n := j
        Exit
      endif
    next
    if n < 1
    // {Журнал,Рекорд на документ,
    //  {Массив RecNo записей взятых на редактирование}
    //  {Массив RecNo д-тов для которых создали строки} }

      AADD(::maTbDoc,{nJrn,,{},{}})
      i := Len(::maTbDoc)

      ::maTbDoc[i][2] := CreateDbRecord(B6_DBF_PATH + ;
                         ::aTab[k][1] ;
                         ,::aTab[k][2])
    else
      i := n
    endif

    if ::maTbDoc[i][2]:Seek(cIdDoc,.T.,::aTab[k][2])
      nRec := ::maTbDoc[i][2]:RecNo()
      if ::maTbDoc[i][2]:Lock()
        //Массив документов с которыми стартовали
        AADD(::maTbDoc[i][3],::maTbDoc[i][2]:RecNo())
      else
        Break(.F.)
      endif
    endif
    dbSfDoc:Skip(1)
  Enddo
  */
 recover using oErr
  //::maDoc := {}
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

Method clsTax_Inv:GetPSchName(cSchet,cValue)
local  oErr
 begin sequence
 /*
 if Select(::mTbPSch) < 1 // == nil
   //::mTbPSch := CreateDbRecord(B6_DBF_PATH + "Plan_sch.Dbf","CODE")
   _DbAreaOpen(B6_DBF_PATH + "Plan_sch.Dbf", @::mTbPSch, "CODE")
 endif
 */
 if (DIC_PLAN_SCH)->(DbSeek(Upper(cSchet)))
   cValue := (DIC_PLAN_SCH)->NAME_SCH
 else
   Break(.F.)
 endif
 recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

Method clsTax_Inv:GetSfFieldName(cStrTp)
local cFieldName
   cFieldName := ""
   Do case
     Case cStrTp == "0"
       cFieldName := ::aTab[1][4]
     Case cStrTp == "1"
       cFieldName := ::aTab[2][4]
     Case cStrTp == "2"
       cFieldName := ::aTab[3][4]
     Case cStrTp == "3"
       cFieldName := ::aTab[4][4]
     Case cStrTp == "4"
       if (::mAliasInv)->TI_CTG == "1"
         cFieldName := ::aTab[5][4]
       else
         cFieldName := ::aTab[6][4]
       endif
   endcase
Return cFieldName

Method clsTax_Inv:GetNextNumInv(lReg)
local cKey
  if !(ValType(lReg) == "L")
    lReg := .F.
  endif
  if lReg
    ::NumRule(2):NControlMem()
    cKey := (::mAliasInv)->DOC_TP + left(DTOS((::mAliasInv)->REG_DATE),4)
    ::ds:FieldValue("REG_NUM",::NumRule(2):NWDoc(cKey,"SFREG"))
  else
    ::LenNum()
    if (::mAliasInv)->TI_CTG == "2" .Or. (::mAliasInv)->DEF

      if (::cWA)->DEF
        cKey := (::cWA)->SFD_ID
        ::NumRule(1):NControlMem()
        if Empty(cKey)
          ::ds:FieldValue("DOC_NUM","")
        else
          ::ds:FieldValue("DOC_NUM",::NumRule(1):NWDoc(cKey,"SFDEF"))
        endif
      else
        cKey := (::mAliasInv)->DOC_TP + left(DTOS((::mAliasInv)->DOC_DATE),4)
        ::NumRule(1):NControlMem()
        ::ds:FieldValue("DOC_NUM",::NumRule(1):NWDoc(cKey,"SFDOC"))
      endif
    endif
  endif
Return .T.

Method clsTax_Inv:LenNum()
local RetValue,cKey,cAl,cNomer
local fc15 := GlobalVarsGet("FC_0015")
  if (::mAliasInv)->TI_CTG == "1"
    RetValue := len((::cWa)->DOC_NUM)
  else
    if !GetTaxParamIni("LEN_NUM",@RetValue)
      RetValue := len((::cWa)->DOC_NUM)
    else
      if Empty(RetValue)
        RetValue := len((::cWa)->DOC_NUM)
      endif
    endif
  endif
  if (::mAliasInv)->TI_CTG == "1" .And. !(::cWA)->DEF
    Return RetValue
  endif
  cKey := (::mAliasInv)->DOC_TP + left(DTOS((::mAliasInv)->DOC_DATE),4)
  if (::cWA)->DEF
    ::mNumeratorRule[1,3] := "TAG_SFD"
    ::mNumeratorRule[1,5] := "SFDEF"
    ::mNumeratorRule[1,6] := "SFD_ID"
    ::NumRule(1):aSetNum := {, , RetValue}
    ::NumRule(1):TagName := "TAG_SFD"
    cKey := "SFDEF" + (::mAliasInv)->SFD_ID
  else
    ::mNumeratorRule[1,3] := "TAG_NUM"
    ::mNumeratorRule[1,5] := "SFDOC"
    ::mNumeratorRule[1,6] := "DOC_TP + left(DTOS(REG_DATE),4)"
    ::NumRule(1):aSetNum := {, , RetValue}
    ::NumRule(1):TagName := "TAG_NUM"
    cKey := "SFDOC" + cKey
  endif
  if ! _DbAreaOpen(B6_DBF_PATH + "TAX\MEMDAT.dbf", @cAl,"TAG_IDENT")
    return RetValue
  endif
  if (cAl)->(DbSeek(cKey))
    if RetValue < (cAl)->Len
      if (cAl)->(DbRLock((cAl)->(RecNo())))
        cNomer := AllTrim((cAl)->Value)
        cNomer := REMLEFT(cNomer," ")
        cNomer := REMLEFT(cNomer,"0")
        cNomer := PADLEFT(cNomer,RetValue, fc15)

        (cAl)->Value := cNomer
        (cAl)->Len := RetValue
        (cAl)->(DbRUnLock((cAl)->(RecNo())))
      endif
    endif
  endif
  _DbAreaClose(cAl)
Return RetValue

Method clsTax_Inv:OldCard()
local  oErr,cKey//,tbReg

 begin sequence
 //altd()
 if /*_IS_UDAL  .Or.*/ (::mAliasInv)->MOVE_TP $ {"ПП","ПР"}
   ::mCardId := "" //0
   ::mCardPartner := ""
   ::mCardRecNo := 0
   ::mlRegDoc := .F.
   Break(.T.)
 endif
 if !(ValType(::mTbCard) == "O")
   ::mTbCard := CreateDbRecord(B6_DBF_PATH + "AP\ap_card.dbf", "TAG_OSN")
 endif
 cKey := (::mAliasInv)->DOC_ID // STR(1601,10,0) + ::DS:DOC_ID //str(::DS:DOC_ID,10,0)
 if ::mTbCard:Seek(cKey,.T.,"TAG_DOC")
   ::mCardId := ::mTbCard:CARD_ID
   ::mCardPartner := ::mTbCard:PART_ID
   ::mCardRecNo := ::mTbCard:RecNo()
   if !(ValType(::mTbApReg) == "O")
     ::mTbApReg := CreateDbRecord(B6_DBF_PATH + "AP_REG.dbf", "CDPS")
   endif
   //tbReg:Scope(str(::mCardId,10,0),str(::mCardId,10,0),"TAG_CARD")
   ::mTbApReg:Scope(::mCardId,::mCardId,"CDPS")
   ::mTbApReg:MoveFirst()
   If ::mTbApReg:Eof()
     ::mlRegDoc := .F.
   else
     ::mlRegDoc := .T.
   endif
 else
   ::mCardId := "" //0
   ::mCardPartner := ""
   ::mCardRecNo := 0
   ::mlRegDoc := .F.
 endif
 recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence

Return .T.
////////////////////
// PG 26.11.04
// синхронизация карточки с С-Ф
///////////////////
Method clsTax_Inv:CheckCard()
local oErr
Local cPartner := (::mAliasInv)->PRT_ID
Local nTypeAp := If((::mAliasInv)->TI_CTG == "1",1,2)
Local aParam := {}
Local lRet := .F.,lReg := .F.
Local cCntType := "",nSumCard,nSumDoc
 begin sequence
 //altd()
 if (::mAliasInv)->MOVE_TP $ {"ПП","ПР"}
   Break(.T.)
 endif
 if !(ValType(::mTbCard) == "O")
   ::OldCard()
 endif

 if TakePartnerParamForAP(cPartner,nTypeAp,@aParam,@lRet)
   if lRet .And. (aParam[1] == "2")
     if aParam[2]  == "3"
       cCntType := aParam[2]
       lReg := .T. // Документ нужно зарегистрировать в карточке с-ф
     endif
   endif
 else
   Break(.F.)
 endif
 AADD(::maTran,::mTbCard:Alias())
 (::mTbCard:Alias())->( WaEdit() )
 Do case
 //Если С-Ф новый и регистрить в с-ф не нужно
   case ::EditMode == 2 .And. !lReg
     Break(.T.)
  //Если С-Ф новый и регистрить нужно
   case ::EditMode == 2 .And. lReg
     if !::CreateCard(/*aParam,*/nTypeAp)
       break(.F.)
     endif
  //Если С-Ф редактирование регистрить нужно
  // а старой карточки нет - создаем карточку
   case ::EditMode == 1 .And. lReg .And. Empty(::mCardId)
     if !::CreateCard(/*aParam,*/nTypeAp)
       break(.F.)
     endif
  //Если С-Ф редактирование - регистрить не нужно
  // а есть стараяч карточка - удаляем карточку
   case ::EditMode == 1 .And. !lReg .And. !Empty(::mCardId)
     if !::DeleteCard()
       break(.F.)
     endif

   //Если С-Ф редактирование и изменили партнера и его нужно регистрить
  // а есть стараяч карточка - синхронизируем карточку
   case  lReg .And. ::EditMode == 1 .And. !(::mCardPartner == ::PRT_ID)  .And. !Empty(::mCardId)
     if !::DeleteCard()
       break(.F.)
     endif
     if !::CreateCard(/*aParam,*/nTypeAp)
       break(.F.)
     endif
     //Если С-Ф редактирование и изменили сумму
    // а есть стараяч карточка - синхронизируем карточку
   case  ::EditMode == 1 .And. (::mCardPartner == ::PRT_ID)  .And. !Empty(::mCardId)
     nSumCard := ::mTbCard:FieldValue("AMNT")
     nSumDoc  := (::mAliasInv)->SUM_A
     If  !(::mAliasInv)->DOC_DATE==::mTbCard:CNREGD .or.;
         !(::mAliasInv)->REG_DATE ==::mTbCard:CNJURD .or.;
         !(::mAliasInv)->REG_NUM  ==::mTbCard:CNREGNO.or.;
         !(::mAliasInv)->DOC_NUM  ==::mTbCard:CNJURNO .or.;
         !(::mAliasInv)->CODE_TP  ==::mTbCard:CNTYPE
        If ::mTbCard:Lock()
           ::mTbCard:CNREGD :=(::mAliasInv)->DOC_DATE
           ::mTbCard:CNJURD :=(::mAliasInv)->REG_DATE
           ::mTbCard:CNREGNO:=(::mAliasInv)->REG_NUM
           ::mTbCard:CNJURNO:=(::mAliasInv)->DOC_NUM
           ::mTbCard:CNTYPE :=(::mAliasInv)->CODE_TP
           ::mTbCard:UnLock()
        Endif
     Endif
     if !ConvertingSummDocForCardAp(::mTbCard:CUR_ID,(::mAliasInv)->VAL_ID,@nSumDoc,(::mAliasInv)->DOC_DATE,,.F.)
       Break(.F.)
     endif
     if !(Round(nSumCard,6) == Round(nSumDoc,6))
       /*
       if !ConvertingSummDocForCardAp(::mTbCard:CUR_ID,(::mAliasInv)->VAL_ID,@nSumDoc,(::mAliasInv)->DOC_DATE,,.F.)
         Break(.F.)
       endif
       */
       if ::mTbCard:Lock()
         ::mTbCard:FieldValue("AMNT",nSumDoc)
         ::mTbCard:UnLock()
       endif
     endif
 endcase
 recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

Method clsTax_Inv:CardYes()
Return /*!_IS_UDAL .And.*/!Empty(::mCardId)

Method clsTax_Inv:CreateCard(/*aParam,*/nTypeAp)
local oErr//,cTbName,cLocate,lRet,cName,RetValue,oObjCard
local cCard//,cMsg//aSchet,n,lRet
 begin sequence

 cCard  := ""

 if !CreateCardAp((::mAliasInv)->PRT_ID,;
                  nTypeAp,;
                  @cCard,;
                  '2',;
                  ::VALCODE,;
                  '3',;
                  (::mAliasInv)->DOC_ID,;
                  (::mAliasInv)->SUM_A,;
                  (::mAliasInv)->DOC_DATE,;
                  (::mAliasInv)->REG_DATE,;
                  (::mAliasInv)->REG_NUM,;
                  (::mAliasInv)->DOC_NUM,;
                  (::mAliasInv)->CODE_TP,;
                   ::mTbCard)
   Messagebox("Не удалось создать карточку расчетов!" + CRLF + "Повторите сохранение счета-фактуры!" ,TITLEAPP,48)
   Break(.F.)
 endif
 ::mCardId := cCard

 recover using oErr

  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

Method clsTax_Inv:DeleteCard()
local oErr,aMsgDoc := {,}
 begin sequence
 // старая карточка есть - регистрационных записей нет
 //altd()
 if !(ValType(::mTbCard) == "O")
   ::OldCard()
 endif
 if !Empty(::mCardId)
   if !DelCardBrg(::DOC_ID,aMsgDoc)
     if !Empty(aMsgDoc[1])
       AADD(::aMsqNotSave,aMsgDoc[1])
     endif
     Break(.F.)
   endif
   ::mCardId := ""
   ::mCardPartner := ""
   ::mCardRecNo := 0
   ::mlRegDoc := .F.

   /*
   if ::mlRegDoc
   // Разрегистрим все документы под эту карточку

     Break(.F.)
   endif
   ::mTbCard:GoTo(::mCardRecNo)
   if !::mTbCard:Locked()
     if !::mTbCard:Lock()
       Break(.F.)
     endif
   endif
   ::mTbCard:Delete()
   */
 endif

 recover using oErr
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

method clsTax_Inv:DelAllStr()
  local i, oStr,dssum,n
  //удалим ссылки на документы //удалим tax_str (спецификацию)
   oStr := ::TAX_STR
   oStr:GoTop()
   oStr:mDocDelete := .T.
   Do While !oStr:ds:Eof()
     ::TAX_STR:TAXSTRSUM:GoTop()
     dssum := ::TAX_STR:TAXSTRSUM:DS
     Do While !dssum:Eof()
        dssum:Delete()
        dssum:Skip(1)
     enddo
     ::TAX_STR:COMMENTM:GoTop()
     dssum := ::TAX_STR:COMMENTM:DS
     Do While !dssum:Eof()
        dssum:Delete()
        dssum:Skip(1)
     enddo

     oStr:ds:Delete()
     oStr:ds:Skip(1)
    enddo
    oStr:mDocDelete := .F.
    n := len(::aSfDoc)
    if ::mlYesDoc
      for i := 1 to n
        if  !(::aSfDoc[i][_STATUS] == 1)
          ::aSfDoc[i][_DEL] := .T.
        else
          ADel( ::aSfDoc, i )
          i := i - 1
          n := n - 1
          ASize( ::aSfDoc, n )
        endif
      next
    else
      ::aSfDoc := {}
    endif
  /*for i := 1 to 2
    ds := iif( i == 1, ::SFDOC:DS, ::TAX_STR:DS )
    ds:GoTop()
    if i == 1
      ::Tax_Str:mDocDelete := .T.
    endif
    Do While !ds:Eof()
      if i == 2
        ::TAX_STR:TAXSTRSUM:GoTop()
        dssum := ::TAX_STR:TAXSTRSUM:DS
        Do While !dssum:Eof()
          ds:Delete()
          dssum:Skip(1)
        enddo
      endif
      ds:Delete()
      ds:Skip(1)
    enddo

    if i == 1 // Почистим налоги под документ
       ::Tax_Str:mDocDelete := .F.
    endif
  next
  */
  //ds := nil
return nil

Method clsTax_Inv:CreateForScladZapasTovarReal(oObjDoc,lVMain,nFor,aLock,cAliasStr)
local  oErr
local tb,tbStr ,valKey,i,n,k,lValuta := .F.,nJrn ,cAnalit := "",lAnalit := .F.,lFirst := .F.
local cTbName := "",cTagName := "", cStrType := "",nRate := 1 ,nRet
local cLabelName := "",cNnumName := "",cCode := Space(24),cEd := "",lRet := .F.,cLabelKey := ""
local lPrichod := .F.,aRec := {},lGroup := .F.//,aNnumNameEd := {}
Local aRegSfDoc := {},a
Local cAlStCom,nStr, cDocJrn, cDocDim := "", cSfDocDim
Local cMlabel := ""
Local cPart := "",cTbPrt := ""
Local nK := 1,cKey,cTbComment,cAlCom
Local cSchet := "",lFirstSch := .F.,lSchet := .F. ,lAdd,lAddDoc
Local cDop := "",cCom := "",cPer := '"' + chr(13) + ',' + chr(10) + '"'
Local cKOPNDS := Space(2),cKOPNNDS := Space(7),cKOPNDS0 := Space(7),cKOPAGNDS := Space(7)
Local cTbSort, cKeySort, cTagSort,cSortField, rez
Local cCntTp := "",cCntTpRec := "",cCntDoc := "",cCntDocRec := "",cIdObl := "",lFirsCnt := .F.,lCnt := .F.
Local cTbMLabelAG := "", cAlAg := ""
 begin sequence
// altd()
 tb := oObjDoc
 do case
   case nFor == 0 // склад
     //cTbName := "Sclad\MDocm.dbf"
     cTagName := "TAG_OPER_"
     cLabelName := "Sclad\MLabel.dbf"
     cTbPrt := "Sclad\spr_part.dbf"
     cStrType := "2"
     cTbComment := "Sclad\CommentM.dbf"
     cTbMLabelAG := "SCLAD\MLABELAG.DBF"
     if  (tb)->Vid == "1" //Tb:Vid == "1"  // по постановке для расходных документов - берем сумму налога
       lPrichod := .T.  // для приходных - рассчитываем
     endif
     nJrn := "0301"
     cTbSort := "Sclad\MOVES.dbf"
     cKeySort := "VID+TYPE+TYPEEX"
     cTagSort := "MOVES_VE"
     cSortField := "PreSort"
   case nFor == 1 // запас
     //cTbName := "Zapas\MDocm.dbf"
     cTagName := "TAG_OPER_"
     cLabelName := "Zapas\MLabel.dbf"
     cTbPrt := "Zapas\spr_part.dbf"
     cStrType := "3"
     cTbComment := "Zapas\CommentM.dbf"
     if  (tb)->Vid == "1" //  Tb:Vid == "1"  // по постановке для расходных документов - берем сумму налога
       lPrichod := .T.  // для приходных - рассчитываем
     endif
     nJrn := "0901"
     cTbSort := "Zapas\MOVES.dbf"
     cKeySort := "VID+TYPE+TYPEEX"
     cTagSort := "MOVES_VE"
     cSortField := "PreSort"
   case nFor == 2 // акты на закупку
     //cTbName := "TOVAR\ACT_OP.dbf"
     cTagName := "TAG_NUMPP" //"TAG_NNOPER"
     cLabelName := "TOVAR\MLabel.dbf"
     cTbComment := "TOVAR\CommentM.dbf"
     cStrType := "4"
     nJrn := "TV01"//1201
     cTbSort := "TOVAR\MEMDAT.dbf"
     cKeySort := Upper(AllTrim(m->B6_USER_NAME)) + "СОРТИРОВКА СТРОК АКТОВTV"
     cTagSort := "TAG_IDENT"
     cSortField := "VALUE"
   case nFor == 3 // акты на продажу
     //cTbName := "REAL\ACT_OP.dbf"
     cTagName := "TAG_NUMPP"//"TAG_NNOPER"
     cLabelName := "TOVAR\MLabel.dbf"
     cTbComment := "REAL\CommentM.dbf"
     cStrType := "4"
     nJrn := "0501"
     cTbSort := "SCLAD\MEMDAT.dbf"
     cKeySort := Upper(AllTrim(m->B6_USER_NAME)) + "СОРТИРОВКА СТРОК АКТОВ05"
     cTagSort := "TAG_IDENT"
     cSortField := "VALUE"
 endcase

 if ::mParamIni[_TAX_SM_PS] //.Or. ::mGroupSf
   lGroup := .T.
 endif
 //удалим ссылки на документы //удалим спецификацию
 ::DelAllStr()

 if ! _DbAreaOpen(B6_DBF_PATH + cTbComment, @cAlCom,"TAG_OPER")
   Break(.F.)
 endif

 if !Empty(cTbMLabelAG) .And. File(B6_DBF_PATH + cTbMLabelAG)
   if ! _DbAreaOpen(B6_DBF_PATH + cTbMLabelAG , @cAlAg,"ROWID")
     Break(.F.)
   endif
 else
   cTbMLabelAG := ""
 endif

 tbStr := cAliasStr
 if ! _DbAreaOpen(B6_DBF_PATH + cLabelName, @cMlabel,"MLABEL")
   Break(.F.)
 endif
 if !Empty((::mAliasInv)->ACNT_ID) //.And. !Empty((::mAliasInv)->ANALIT)//Есть счет  и аналитика
   if (DIC_PLAN_SCH)->(DbSeek(Upper((::mAliasInv)->ACNT_ID)))
      lAnalit := (DIC_PLAN_SCH)->analit_y_n
   endif
 elseif Empty((::mAliasInv)->ACNT_ID) // счет нужно брать из документа
   lSchet := .T.  // перепишем счет из документов
 endif
 for i := 1 to len(aLock)
 // altd()
    (tb)->(DbGoTo(aLock[i]))//tb:GoTo(aLock[i]/*::aLockRec[i]*/)
    if i == 1
      ::mnSort := -1
      lRet := .F.
      if nJrn $ "0301,0901"
        cKeySort := Upper((tb)->VID + (tb)->TYPE + (tb)->TYPEEX)
      endif
      //cKeySort := (tb)->&(cKeySort)
      if LookUpSeek(cTbSort,cTagSort,@lRet,cKeySort,cSortField,@Rez )
        if lRet
          if nJrn $ "0301,0901"
            if Rez < 1
              Rez := 1
            endif
            ::mnSort := Rez
          elseif nJrn $ "TV01,0501"
            ::mnSort := NumSortForSFAct(Upper(AllTrim(Rez)))
          endif
        endif
      endif

    endif
    //if !Empty(::DS:FieldValue("ACNT_ID")) .And. !Empty(::DS:FieldValue("ANALIT"))//Есть счет  и аналитика
    //   lAnalit := .T.
      if Empty(cDop) .And. ::mParamIni[_TAX_DOPSF]
        cDop := (tb)->Prim
      endif
      if ::mParamIni[_TAX_COMCF]
        if nJrn $ {"0301","0901"}
          cCom := cCom + AllTrim((tb)->SCLADS)
        else
          cCom := cCom + AllTrim((tb)->KOMMENT)
        endif
        if !(right(cCom,1,1) $ cPer)
          cCom := cCom + chr(13) + chr(10)
        endif
      endif
       do case
         case nJrn $ {"0301","0901"}
           if i == 1
             cAnalit := (tb)->agentcode
             cSchet := (tb)->schet_a
             cDocJrn := "DOC" + (tb)->JRN_CODE
             cDocDim := (tb)->DOCDIM
           else
             if !(cAnalit == (tb)->agentcode) //аналитики разные
               lFirst := .T.
             endif
             if !(cSchet == (tb)->schet_a) //аналитики разные
               lFirstSch := .T.
             endif
           endif
         case nJrn $ {"0501","TV01"/*1201*/}
           if i == 1
             cAnalit := (tb)->Code
             cSchet := (tb)->schet
             cDocJrn := "DOC" + nJrn
             cDocDim := (tb)->DOCDIM
           else
             if !(cAnalit == (tb)->Code)
               lFirst := .T.
             endif
             if !(cSchet == (tb)->schet) //аналитики разные
               lFirstSch := .T.
             endif
           endif
       endcase

    //endif
    if cStrType == "4"
      nRate := iif(!Empty((tb)->curs),(tb)->curs,1)
    else
      nRate := iif(!Empty((tb)->CENAVAL),(tb)->CENAVAL,1)
    endif
    if !lVMain //С-Ф валютная
      if (tb)->CODEVAL == ::VALCODE // валюта документа совпадает с валютой с-ф
        lValuta := .T. // NDS и сумму - пересчитываем в валюту С-Ф
      else
        messagebox("Валюта документа не соответствует валюте счета-фактуры!",TITLEAPP,48)
        Break(.F.)
      endif
    endif

    if Empty(cKOPNDS)
      cKOPNDS :=  (tb)->KOP_NDS
    endif
    if Empty(cKOPNNDS)
      cKOPNNDS :=  (tb)->KOP_NNDS
    endif
    if Empty(cKOPNDS0)
      cKOPNDS0 :=  (tb)->KOP_NDS0
    endif
    if Empty(cKOPAGNDS)
      cKOPAGNDS :=  (tb)->KOP_AG_NDS
    endif

    cCntTpRec := (tb)->BRG_TYPE
    if cCntTpRec == "1"
      cCntDocRec := (tb)->ID_Reg
    elseif cCntTpRec == "2"
      cCntDocRec := (tb)->order_id
    elseif cCntTpRec == "3"
      cCntDocRec := (tb)->oper_fact
    endif
    if i == 1
      if !Empty(cCntDocRec) .And.  !(cCntTp == "3")
        cCntTp := cCntTpRec
        cCntDoc := cCntDocRec
        cIdObl := (tb)->ID_OBL
      endif
    else
      if Empty(cCntDoc) //
        if !Empty(cCntDocRec) .And.  !(cCntTp == "3")
          cCntTp := cCntTpRec
          cCntDoc := cCntDocRec
          cIdObl := (tb)->ID_OBL
        endif
      else
        if !Empty(cCntDocRec)
          if !(cCntDoc == cCntDocRec) //документы основания разные
            lFirsCnt := .T.
          endif
        endif
      endif
    endif
       /*
        if !(Empty(obj:KOP_NNDS) .Or. (cKOPNNDS == obj:KOP_NNDS)) .Or.;
           !(Empty(obj:KOP_NDS0) .Or. (cKOPNDS0 == obj:KOP_NDS0)) .Or.;
           !(Empty(obj:KOP_AG_NDS) .Or. (cKOPAGNDS == obj:KOP_AG_NDS))
              messagebox("Коды операций по НДС в документах разные." + chr(13) + chr(10) + "Формирование одного счета-фактуры невозможно.",TITLEAPP,48)
              break(.F.)
        endif
        */


     //Введен идентификатор д-та
     valKey :=  (tb)->NNOPER
     //tbStr:=CreateDbRecord(B6_DBF_PATH + cTbName,cTagName)
     //tbStr:Scope(valKey,valKey,cTagName) //"MDOCM")
     (tbStr)->(OrdSetFocus(cTagName))
     (tbStr)->(OrdScope(0,valKey))
     (tbStr)->(OrdScope(1,valKey))
     (tbStr)->(DbGoTop())
     //altd()
     nStr := 0
     if !::CreateArrayFromStr(tbStr,@aRec,lValuta,lPrichod,;
                            nRate,(tb)->L_NDS,(tb)->L_ACZ,lGroup,;
                            aLock[i],cStrType,cMLabel,@nStr,Len(aLock)>1)
       Break(.F.)
     endif
  next
  (tbStr)->(OrdScope(0,nil))
  (tbStr)->(OrdScope(1,nil))
   //altd()
  for i := 1 to len(aRec)
   if (aRec[i][6][1] > 0) .Or. ( (aRec[i][6][1] == 0) .And. !::mGroupSf)
     if !::TAX_STR:BeforAppend(cStrType,.T.)
       messagebox("Не удалось создать строку счета-фактуры!",TITLEAPP,48)
       Break(.F.)
     endif
     if !::TAX_STR:Append()
       messagebox("Не удалось создать строку счета-фактуры!",TITLEAPP,48)
       Break(.F.)
     endif
     (::mAliasStr)->STR_SRC := .T.
     (::mAliasStr)->GROUP_CODE := aRec[i][2]//tbStr:GRUP
     (::mAliasStr)->NNUM := aRec[i][3]//tbStr:NNUM
     cLabelKey := Upper(aRec[i][2] + aRec[i][3]) // позиционирование в таблице артикулов
     //aNnumNameEd := {}
     if cStrType == "4"  // получаем название а для актов и ед. измерения  артикула
        lRet := (cMLabel)->(DbSeek(cLabelKey))
        if lRet
          cNnumName := (cMLabel)->name
          cEd := (cMLabel)->ED
        endif
        /*
        if LookUpSeek(cLabelName,"MLABEL",@lRet,cLabelKey,{"name","ED"},@aNnumNameEd)
          if lRet
            cNnumName := aNnumNameEd[1]
            cEd := aNnumNameEd[2]
          endif
        endif
        */
        (::mAliasStr)->UNIT := cEd
     else
       //LookUpSeek(cLabelName,"MLABEL",lRet,cLabelKey,{"name","code"},@aNnumNameEd)
       lRet := (cMLabel)->(DbSeek(cLabelKey))
       if lRet
         cNnumName := (cMLabel)->name
         cCode := (cMLabel)->code
         if Empty(aRec[i][4])
           (::mAliasStr)->Country := (cMLabel)->NameCount
         endif
       endif
       (::mAliasStr)->UNIT := aRec[i][5] //tbStr:ED1
       (::mAliasStr)->MDIM := aRec[i][30]
       //cNnumName := aNnumNameEd[1]
       //cCode := aNnumNameEd[2]
     endif
     (::mAliasStr)->CODE := cCode
     (::mAliasStr)->NNAME := cNnumName
     (::mAliasStr)->PRT_CODE := aRec[i][4] //tbStr:PARTIA
     // Если есть партия - получим ГТД и Страну
     if !Empty(aRec[i][4])
       if Select(cPart) < 1
         _DbAreaOpen(B6_DBF_PATH + cTbPrt, @cPart,"TAG_NUM")
       endif
       if Select(cPart) > 0
         if (cPart)->(DbSeek(Upper(aRec[i][2] + aRec[i][3] + aRec[i][4])))
           (::mAliasStr)->GTD := (cPart)->GTD
           (::mAliasStr)->Country := (cPart)->Country
         endif
       endif
     endif

     (::mAliasStr)->R := aRec[i][25] //tbStr:R
     (::mAliasStr)->QNTY     := aRec[i][6][1] + aRec[i][31][1] - aRec[i][32][1]//tbStr:KOLOUT
     (::mAliasStr)->QNTY_BAS := aRec[i][6][2] + aRec[i][31][2] - aRec[i][32][2]
     (::mAliasStr)->QNTY_SHP := (::mAliasStr)->QNTY_BAS//(::mAliasStr)->QNTY
     //::TAX_STR:DS:PRICE := aRec[i][26]//iif(lValuta, tbStr:CENAOUT,tbStr:CENAOUT * tb:CENAVAL)*::mMultyStorno
     //Пересчитаем на количество брака, недостачи и возврата
     if aRec[i][6][1] = (::mAliasStr)->QNTY // общее к-во не нужно коректировать
       nK := 1 //к-циент пересчета на разницу к-ва д-та и с-ф
     else
       nK := (::mAliasStr)->QNTY/aRec[i][6][1]
     endif
     // Если ставка нулевая - рассчитываем по налоговой модели
     // Для акциза нет нулевой ставки
     // 28059 Всегда переносим из документа.
     //if Empty(aRec[i][17])
     //  ::TAX_STR:TAXSTRSUM:MoveFirst()
     //  if Alltrim(::TAX_STR:TAXSTRSUM:SYS_NUM) == "1"
     //    ::TAX_STR:TAXSTRSUM:GetTaxSum(aRec[i][15] * nK )
    //   else
     //    ::TAX_STR:TAXSTRSUM:GetTaxSum(aRec[i][19] * nK)
    //   endif
     //else
       (::mAliasStr)->SUM_NNDS := aRec[i][22] * nK
       (::mAliasStr)->SUM_NDS := aRec[i][23] * nK
       (::mAliasStr)->SUM_A := aRec[i][24] * nK
      /*
     //pg 21389 tax_str.price=tax_str.SUM_NNDS/mdocm.kolout

       if (::mAliasStr)->QNTY == 0
         (::mAliasStr)->PRICE := (::mAliasStr)->SUM_NNDS
       else
         (::mAliasStr)->PRICE := BS_ROUND((::mAliasStr)->SUM_NNDS / (::mAliasStr)->QNTY,8) //aRec[i][6]
       endif
      */

      //48786 Счет-фактура и документ-источник.  Наводим порядок с ценами
       if  (Round(aRec[i][8],8) == 0 .And. Round(aRec[i][9],8) == 0) .Or.;
          ;//независимо от L_ACZ и L_NDS если налогов по строке нет вообще
          ;// MDOCM(ACT_OP).SUM_ACZ=0  MDOCM(ACT_OP).SUM_NDS=0
          (!aRec[i][33][1] .And. aRec[i][33][2] ) .Or.;
          ;//L_ ACZ=true(входит) L_NDS= false(не входит)
          (!aRec[i][33][1] .And. !aRec[i][33][2] .And. Round(aRec[i][9],8) == 0)
          //L_ ACZ= false(не входит) L_NDS= false(не входит)
          //НО акциза по строке НЕТ. т.е. MDOCM(ACT_OP).SUM_ACZ=0

         (::mAliasStr)->PRICE := aRec[i][26]
       elseif (aRec[i][33][1] .And. aRec[i][33][2] .And. (Round(aRec[i][8],8) > 0 .Or. Round(aRec[i][9],8) > 0)) .Or.;
              ;//L_ ACZ=true(входит) L_NDS= true(входит)  и налоги по строке документа есть
              (!aRec[i][33][1] .And. !aRec[i][33][2] .And. Round(aRec[i][9],8) > 0) .Or.;
              ;//L_ ACZ=false(не входит) L_NDS= false(не входит)
              ;//НО акциз по строке ЕСТЬ. т.е. MDOCM(ACT_OP).SUM_ACZ>0
              (aRec[i][33][1] .And. !aRec[i][33][2] .And. Round(aRec[i][9],8) == 0)
              //L_ ACZ= false(не входит) L_NDS= true(входит)
              //НО акциза по строке НЕТ. т.е. MDOCM(ACT_OP).SUM_ACZ=0

         if (::mAliasStr)->QNTY == 0
           (::mAliasStr)->PRICE := (::mAliasStr)->SUM_NNDS
         else
           (::mAliasStr)->PRICE := BS_ROUND((::mAliasStr)->SUM_NNDS / (::mAliasStr)->QNTY,8)
         endif
       endif
       ::TAX_STR:TAXSTRSUM:MoveFirst()
       do while !(::mAliasSum)->(EOF())
         do case
           case Alltrim(::TAX_STR:TAXSTRSUM:SYS_NUM) == "1"
             (::mAliasSum)->TAX_RATE := aRec[i][13]
             (::mAliasSum)->TAX_IDRT := aRec[i][28]
             (::mAliasSum)->TAX_SUM := aRec[i][14] * nK
             (::mAliasSum)->TAX_BASE := aRec[i][15] * nK
             //(::mAliasSum)->TAX_BASEN := aRec[i][16] * nK
             //(::mAliasSum)->TAX_DELTA := 0
             //if Empty(aRec[i][28])
             //  (::mAliasSum)->IS_HAND := .T.
             //else
               (::mAliasSum)->IS_HAND := .F.
             //endif
           case Alltrim(::TAX_STR:TAXSTRSUM:SYS_NUM) == "2"
             (::mAliasSum)->TAX_RATE := aRec[i][17]
             (::mAliasSum)->TAX_IDRT := aRec[i][29]
             (::mAliasSum)->TAX_SUM := aRec[i][18] * nK
             (::mAliasSum)->TAX_BASE := aRec[i][19] * nK
             //(::mAliasSum)->TAX_BASEN := aRec[i][20] * nK
             //(::mAliasSum)->TAX_DELTA := 0
             (::mAliasSum)->IS_HAND := .F.
         endcase
         //(::mAliasSum)->TAX_BASES := aRec[i][21]
         (::mAliasSum)->(DbSkip(1))
       enddo
       //altd()
       // заполняем массив - RecNo д-т, Ключ ст-ка д-та, Ключ стрки С-Ф
     //endif
     for n := 1 to len(aRec[i][10])
       AADD(aRegSfDoc,{aRec[i][10][n],::TAX_STR:STR_ID})
     next

     for n := 1 to len(aRec[i][10])
       /*
       if  !((::mAliasInv)->STR_TP == cStrType )
         (::mAliasInv)->STR_TP := cStrType // есть записи созданные из документов склада
       endif
       */
      /// AADD(aRegSfDoc,{aRec[i][10][n],::TAX_STR:STR_ID})
       a :=  ASORT(aRec[i][10],,,,{|aX,aY|aX[4] < aY[4]})
       if len(a) > 0 //aRec[i][10][n][4] == 1
         if (cAlCom)->(DbSeek(a[1][3]))//(DbSeek(aRec[i][10][n][3]))
           ::TAX_STR:COMMENTM:Append()
           cAlStCom :=  ::TAX_STR:COMMENTM:cWa
           if (cAlStCom)->(DbRLock((cAlStCom)->(RecNo())))
             (cAlStCom)->COMMENT := (cAlCom)->COMMENT
             (cAlStCom)->QDOPCHAR1 := (cAlCom)->QDOPCHAR1
             (cAlStCom)->QDOPCHAR2 := (cAlCom)->QDOPCHAR2
             (cAlStCom)->QDOPNUM1 := (cAlCom)->QDOPNUM1
             (cAlStCom)->QDOPNUM2 := (cAlCom)->QDOPNUM2
             (cAlStCom)->QDOPDATA1 := (cAlCom)->QDOPDATA1
             (cAlStCom)->QDOPDATA2 := (cAlCom)->QDOPDATA2
             if nJrn $ {"0501","0301","0901","0904"}
               (cAlStCom)->KOLFREE := (cAlCom)->KOLFREE
             endif
             if nJrn $ {"0301","0901","0904"}
               (cAlStCom)->QDOPCHAR3 := (cAlCom)->QDOPCHAR3
               (cAlStCom)->QDOPCHAR4 := (cAlCom)->QDOPCHAR4
             endif
             (cAlStCom)->(DbRUnLock((cAlStCom)->(RecNo())))
           endif
           if !(cStrType == "4")
             if !Empty((cAlCom)->AGTD_ID)
               if (cAlAg)->(DbSeek((cAlCom)->AGTD_ID))
                 (::mAliasStr)->GTD := (cAlAg)->NUMGTD
               endif
             endif
           endif
         endif
       endif
     next

   endif

  next
  // отсортируем по документам
  aRegSfDoc := ASort(aRegSfDoc,,,{|aX,aY|aX[1][1] < aY[1][1]})
  valKey := 0
  //cAlSfDoc := ::SFDOC:DS:Alias()
  n := len(::aSfDoc)
  //Добавим в ::aSfDoc документы которых не было изменим статус
  //у документов с которыми стартовали

  For i := 1 to len(aRegSfDoc)
    if n > 0 .And. nJrn ==  ::aSfDoc[1][_JRNID]
      lAdd := .T.
      lAddDoc := .T.
      (tb)->(DbGoTo(aRegSfDoc[i][1][1]))
      for k := 1 to n
        if ::aSfDoc[k][_DOCID] == (tb)->nnoper
          if lAddDoc .And. ::aSfDoc[k][_DOCID] == ::aSfDoc[k][_DOCSTRID]
          // перевыбрали тот же документ
             ::aSfDoc[k][_STATUS] := 0
             ::aSfDoc[k][_DEL] := .F.
             lAddDoc := .F.
          elseif aRegSfDoc[i][1][3] == ::aSfDoc[k][_DOCSTRID]
          // перевыбрана строка, изменился идентификатор строки с-ф
            ::aSfDoc[k][_STATUS] := 3
            ::aSfDoc[k][_SFSTRID] := aRegSfDoc[i][2]
            ::aSfDoc[k][_DEL] := .F.
            lAdd := .F.
          endif
        endif
      next
      if lAdd .Or. lAddDoc
        if lAddDoc //!(valKey == aRegSfDoc[i][1][1])
          //valKey := aRegSfDoc[i][1][1]
          cKey := nJrn+(tb)->NNOPER+"0"
          AADD(::aSfDoc,{(::mAliasInv)->DOC_ID,;
                         (::mAliasInv)->DOC_ID,;
                         (tb)->NNOPER ,;
                         (tb)->NNOPER ,;
                         nJrn,;
                         .F.,;
                         1,cKey,(tb)->(RecNo())})
        endif
        cKey := nJrn+(tb)->NNOPER+"1"
        AADD(::aSfDoc,{(::mAliasInv)->DOC_ID,;
                       aRegSfDoc[i][2],;
                       (tb)->NNOPER ,;
                       aRegSfDoc[i][1][3] ,;
                       nJrn,;
                       .F.,;
                       1,cKey})
      endif
    else
      if !(valKey == aRegSfDoc[i][1][1])
        valKey := aRegSfDoc[i][1][1]
      //Регистрируем документ
        (tb)->(DbGoTo(aRegSfDoc[i][1][1]))//tb:GoTo(aRegSfDoc[i][1][1])
      /*
      if ::SFDOC:Append()
        (cAlSfDoc)->SFSTR_ID := ::DS:FieldValue("DOC_ID")
        (cAlSfDoc)->DOC_ID := tb:NNOPER
        (cAlSfDoc)->DOCSTR_ID := tb:NNOPER
        (cAlSfDoc)->JRN_ID := nJrn
      endif*/
        cKey := nJrn+(tb)->NNOPER+"0"
        AADD(::aSfDoc,{(::mAliasInv)->DOC_ID,;
                       (::mAliasInv)->DOC_ID,;
                       (tb)->NNOPER ,;
                       (tb)->NNOPER ,;
                       nJrn,;
                       .F.,;
                       1,cKey,(tb)->(recNo())})
      endif
    //Регистрируем строки
    /*
    if ::SFDOC:Append()
      (cAlSfDoc)->SFSTR_ID := aRegSfDoc[i][2]
      (cAlSfDoc)->DOC_ID := tb:NNOPER
      (cAlSfDoc)->DOCSTR_ID := aRegSfDoc[i][1][3]
      (cAlSfDoc)->JRN_ID := nJrn
    endif
    */  cKey := nJrn+(tb)->NNOPER+"1"
        AADD(::aSfDoc,{(::mAliasInv)->DOC_ID,;
                       aRegSfDoc[i][2],;
                       (tb)->NNOPER ,;
                       aRegSfDoc[i][1][3] ,;
                       nJrn,;
                       .F.,;
                       1,cKey})
    endif
  next


   //altd()
/* if lAnalit // Есть аналитика - может нужно переписать
   //Аналитики одинаковые ничего переписывать не нужно
   if !(Upper(Alltrim(cAnalit)) ==  Upper(Alltrim(::DS:FieldValue("ANALIT"))))
     if lFirst
       nRet := messagebox("У документов разные аналитические коды." + chr(13) + chr(10) +;
                          "Перенести в счет-фактуру аналитику из первого документа?",TITLEAPP,36)
       if nRet == 6 //Да
         ::DS:FieldValue("ANALIT",cAnalit)
       endif
     else
       ::DS:FieldValue("ANALIT",cAnalit)
     endif
   endif
 endif
*/
 if !Empty(StrTran(cDocDim,"-",""))
   cSfDocDim := (::cWa)->DocDim
   //if ExchangeCodeSegment(cDocJrn,cDocDim,"DOC1601",@cSfDocDim,.T.,.T.,.F.)
     (::cWa)->DocDim := grMaskReFill(cDocJrn,cDocDim,"DOC1601",cSfDocDim, .T.)//cSfDocDim
   //endif
 endif
 if !Empty(cDop) .And. Empty((::mAliasInv)->COMPL_m)
   ::DS:FieldValue("COMPL_m",cDop)
 endif

 if !Empty(cCom) //.And. Empty((::mAliasInv)->COMMENT_M)
   cCom := Left(cCom,len(cCom)-2)
   if !Empty((::mAliasInv)->COMMENT_M)
     cCom := AllTrim((::mAliasInv)->COMMENT_M) + chr(13) + chr(10) + cCom
   endif
   ::DS:FieldValue("COMMENT_M",cCom)
 endif

 if Empty((::mAliasInv)->CNT_DOC_ID)
     (::mAliasInv)->CNT_TYPE := cCntTp
     if !(cCntTp == "3")
       if lFirsCnt
         nRet := messagebox("У документов разные документы основания." + chr(13) + chr(10) +;
                        "Перенести в счет-фактуру документ основания из первого документа?",TITLEAPP,36)
         if nRet == 6 //Да
           (::mAliasInv)->CNT_DOC_ID := cCntDoc
           (::mAliasInv)->ID_OBL := cIdObl
         endif
       else
         (::mAliasInv)->CNT_DOC_ID := cCntDoc
         (::mAliasInv)->ID_OBL := cIdObl
       endif
     endif
 endif

 if !::mlRePlaceMod .And. lSchet
   if lFirstSch
     nRet := messagebox("У документов разные корреспондирующие счета." + chr(13) + chr(10) +;
                        "Перенести в счет-фактуру счет из первого документа?",TITLEAPP,36)
     if nRet == 6 //Да
       ::DS:FieldValue("ACNT_ID",cSchet)
     else
       lAnalit := .F.
     endif
   else
     ::DS:FieldValue("ACNT_ID",cSchet)
   endif
   if (DIC_PLAN_SCH)->(DbSeek(Upper(cSchet)))
      lAnalit := (DIC_PLAN_SCH)->analit_y_n
   endif
 endif
 if !::mlRePlaceMod .And. lAnalit // Есть аналитика - может нужно переписать
   //Аналитики одинаковые ничего переписывать не нужно
   if lSchet
     if lFirst
       nRet := messagebox("У документов разные аналитические коды." + chr(13) + chr(10) +;
                          "Перенести в счет-фактуру аналитику из первого документа?",TITLEAPP,36)
       if nRet == 6 //Да
         ::DS:FieldValue("ANALIT",cAnalit)
       endif
     else
       ::DS:FieldValue("ANALIT",cAnalit)
     endif
   else
     if !Empty(cSchet) .And. (::mAliasInv)->ACNT_ID == cSchet
       if !(Upper(Alltrim(cAnalit)) ==  Upper(Alltrim((::mAliasInv)->ANALIT)))
         if lFirst
           nRet := messagebox("У документов разные аналитические коды." + chr(13) + chr(10) +;
                              "Перенести в счет-фактуру аналитику из первого документа?",TITLEAPP,36)
           if nRet == 6 //Да
             ::DS:FieldValue("ANALIT",cAnalit)
           endif
         else
           ::DS:FieldValue("ANALIT",cAnalit)
         endif
       endif
     elseif !Empty(cSchet) .And. !((::mAliasInv)->ACNT_ID == cSchet)
       if lFirst
         nRet := messagebox("У документов разные аналитические коды." + chr(13) + chr(10) +;
                            "Перенести в счет-фактуру аналитику из первого документа?",TITLEAPP,36)
         if nRet == 6 //Да
           cAnalit := grMaskReFill((::mAliasInv)->ACNT_ID,;
                                   (::mAliasInv)->ANALIT,;
                                   cSchet,;
                                   cAnalit,;
                                    .F.)
           //cAnalit := grMaskReMake(cSchet,cAnalit,(::mAliasInv)->ACNT_ID)
           ::DS:FieldValue("ANALIT",cAnalit)
         endif
       else
         //cAnalit := grMaskReMake(cSchet,cAnalit,(::mAliasInv)->ACNT_ID)
         cAnalit := grMaskReFill((::mAliasInv)->ACNT_ID,;
                                   (::mAliasInv)->ANALIT,;
                                   cSchet,;
                                   cAnalit,;
                                    .F.)
         ::DS:FieldValue("ANALIT",cAnalit)
       endif

     endif
   endif
 endif

 if !Empty(cKOPNDS)
   (::mAliasInv)->KOP_NDS := cKOPNDS
 endif
 if !Empty(cKOPNNDS)
   (::mAliasInv)->KOP_NNDS := cKOPNNDS
 endif
 if !Empty(cKOPNDS0)
   (::mAliasInv)->KOP_NDS0 := cKOPNDS0
 endif
 if !Empty(cKOPAGNDS)
   (::mAliasInv)->KOP_AG_NDS := cKOPAGNDS
 endif

 Break(.T.)
 recover using oErr
  tb := Nil
  tbStr := nil
  _DbAreaClose(cAlCom)
  _DbAreaClose(cAlAg)
  _DbAreaClose(cMlabel)
  _DbAreaClose(cPart)
  /*
  if (valType(tbStr) == "O")
    tbStr:destroy()
  endif
  */
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence

Return .T.

Method clsTax_Inv:CreateForAssets(oObjDoc,aLock,cAliasStr)
local  oErr,lGroup,i,n,k,cCard,a := {},IdNds
local aRegSfDoc := {},valKey ,lAdd := .F.,lAddDoc := .F.
local nJrn := "1701", cKey, cDop
local cDocJrn := "DOC1701", cDocDim := "", cSfDocDim
  begin sequence
  lGroup := ::mParamIni[_TAX_SM_PS]

  //удалим ссылки на документы //удалим спецификацию
  ::DelAllStr()
  if ! _DbAreaOpen(B6_DBF_PATH + "Assets\RES_CARD.Dbf", @cCard,"TAG_ID")
    Break(.F.)
  endif
  (cAliasStr)->(OrdSetFocus("TAG_ID"))

  for i := 1 to len(aLock)
    if Empty(StrTran(cDocDim,"-",""))
      cDocDim := (oObjDoc)->DocDim
    endif
    if Empty(cDop) .And. ::mParamIni[_TAX_DOPSF]
      cDop := (oObjDoc)->COMMENT
    endif
    if Empty(cDop) .And. ::mParamIni[_TAX_DOPSF]
      cDop := (oObjDoc)->COMMENT
    endif
    (oObjDoc)->(DbGoTo(aLock[i]))
    (cAliasStr)->(OrdScope(0,(oObjDoc)->DOC_ID ))
    (cAliasStr)->(OrdScope(1,(oObjDoc)->DOC_ID ))
    (cAliasStr)->(DbGoTop())
    if !::CreateArrStrAssets(cAliasStr,cCard,lGroup,@a,(oObjDoc)->DOC_DATE,@IdNds, (oObjDoc)->(RecNo()))
      break(.F.)
    endif
  next
  if len(a) < 1
  //нет строк с суммами - ничего не будем создавать
    Break(.T.)
  endif

  for i := 1 to len(a)
    if !::TAX_STR:BeforAppend("5",.T.)
      messagebox("Не удалось создать строку счета-фактуры!",TITLEAPP,48)
      Break(.F.)
    endif
    if !::TAX_STR:Append()
      messagebox("Не удалось создать строку счета-фактуры!",TITLEAPP,48)
      Break(.F.)
    endif
    (::mAliasStr)->STR_SRC := .T.
    (::mAliasStr)->GROUP_CODE := a[i][2]
    (::mAliasStr)->NNUM := a[i][3]
    (::mAliasStr)->UNIT := a[i][4]
    (::mAliasStr)->NNAME := a[i][8]
    (::mAliasStr)->R := 1
    (::mAliasStr)->QNTY := a[i][6]
    (::mAliasStr)->QNTY_BAS := a[i][6]
    (::mAliasStr)->QNTY_SHP := a[i][6]
    (::mAliasStr)->SUM_NDS := a[i][7]
    (::mAliasStr)->SUM_A := a[i][5]
    (::mAliasStr)->SUM_NNDS := a[i][5] - a[i][7]
    if BS_ROUND((::mAliasStr)->QNTY,8) == 0
      (::mAliasStr)->PRICE := (::mAliasStr)->SUM_NNDS
    else
      (::mAliasStr)->PRICE := BS_ROUND( ( (::mAliasStr)->SUM_NNDS/(::mAliasStr)->QNTY ),8 )
    endif
    ::TAX_STR:TAXSTRSUM:MoveFirst()
    do while !(::mAliasSum)->(EOF())
      if !Alltrim(::TAX_STR:TAXSTRSUM:SYS_NUM) == "1"
        (::mAliasSum)->TAX_RATE := a[i][10]//18
        (::mAliasSum)->TAX_IDRT := a[i][11]//IdNds
        (::mAliasSum)->TAX_SUM := a[i][7]
        if (::TAX_STR:TAXSTRSUM:maModStr[1][_SUMUSE] == "2")
          (::mAliasSum)->TAX_BASE := a[i][5]
        else
          (::mAliasSum)->TAX_BASE := a[i][5] - a[i][7]
        endif
        (::mAliasSum)->IS_HAND := .F.
      endif
      (::mAliasSum)->(DbSkip(1))
    enddo
    for n := 1 to len(a[i][9])
      AADD(aRegSfDoc,{a[i][9][n],::TAX_STR:STR_ID})
    next
  next


  // отсортируем по документам
  aRegSfDoc := ASort(aRegSfDoc,,,{|aX,aY|aX[1][1] < aY[1][1]})
  valKey := 0

  n := len(::aSfDoc)
  //Добавим в ::aSfDoc документы которых не было изменим статус
  //у документов с которыми стартовали

  For i := 1 to len(aRegSfDoc)
    if n > 0 .And. nJrn ==  ::aSfDoc[1][_JRNID]
      lAdd := .T.
      lAddDoc := .T.
      (oObjDoc)->(DbGoTo(aRegSfDoc[i][1][1]))
      for k := 1 to n
        if ::aSfDoc[k][_DOCID] == (oObjDoc)->DOC_ID
          if lAddDoc .And. ::aSfDoc[k][_DOCID] == ::aSfDoc[k][_DOCSTRID]
          // перевыбрали тот же документ
             ::aSfDoc[k][_STATUS] := 0
             ::aSfDoc[k][_DEL] := .F.
             lAddDoc := .F.
          elseif aRegSfDoc[i][1][3] == ::aSfDoc[k][_DOCSTRID]
          // перевыбрана строка, изменился идентификатор строки с-ф
            ::aSfDoc[k][_STATUS] := 3
            ::aSfDoc[k][_SFSTRID] := aRegSfDoc[i][2]
            ::aSfDoc[k][_DEL] := .F.
            lAdd := .F.
          endif
        endif
      next
      if lAdd .Or. lAddDoc
        if lAddDoc
          cKey := nJrn+(oObjDoc)->DOC_ID +"0"
          AADD(::aSfDoc,{(::mAliasInv)->DOC_ID,;
                         (::mAliasInv)->DOC_ID,;
                         (oObjDoc)->DOC_ID ,;
                         (oObjDoc)->DOC_ID ,;
                         nJrn,;
                         .F.,;
                         1,cKey,(oObjDoc)->(RecNo())})
        endif
        cKey := nJrn+(oObjDoc)->DOC_ID+"1"
        AADD(::aSfDoc,{(::mAliasInv)->DOC_ID,;
                       aRegSfDoc[i][2],;
                       (oObjDoc)->DOC_ID ,;
                       aRegSfDoc[i][1][3] ,;
                       nJrn,;
                       .F.,;
                       1,cKey})
      endif
    else
      if !(valKey == aRegSfDoc[i][1][1])
        valKey := aRegSfDoc[i][1][1]
      //Регистрируем документ
        (oObjDoc)->(DbGoTo(aRegSfDoc[i][1][1]))

        cKey := nJrn+(oObjDoc)->DOC_ID+"0"
        AADD(::aSfDoc,{(::mAliasInv)->DOC_ID,;
                       (::mAliasInv)->DOC_ID,;
                       (oObjDoc)->DOC_ID ,;
                       (oObjDoc)->DOC_ID ,;
                       nJrn,;
                       .F.,;
                       1,cKey,(oObjDoc)->(recNo())})
      endif
    //Регистрируем строки
        cKey := nJrn+(oObjDoc)->DOC_ID+"1"
        AADD(::aSfDoc,{(::mAliasInv)->DOC_ID,;
                       aRegSfDoc[i][2],;
                       (oObjDoc)->DOC_ID ,;
                       aRegSfDoc[i][1][3] ,;
                       nJrn,;
                       .F.,;
                       1,cKey})
    endif
  next


  if !Empty(StrTran(cDocDim,"-",""))
     cSfDocDim := (::cWa)->DocDim
     //if ExchangeCodeSegment(cDocJrn,cDocDim,"DOC1601",@cSfDocDim,.T.,.T.,.F.)
       (::cWa)->DocDim := grMaskReFill(cDocJrn,cDocDim,"DOC1601",cSfDocDim, .T.)//cSfDocDim
     //endif
  endif
  if !Empty(cDop) .And. Empty((::mAliasInv)->COMPL_m)
     (::mAliasInv)->COMPL_m := cDop
  endif

  Break(.T.)
  recover using oErr
    _DbAreaClose(cCard)
    if valtype(oErr) == "L"
      return oErr
    else
      return .F.
    endif
  end sequence
return .T.

Method clsTax_Inv:CreateForFinDoc(oObjDoc,nFor,aLock)
local  oErr,aSelectDoc := {},StrTp,n,m,k,lAdd := .F.
Local i,cJrn ,cKey ,dDocDate ,nTaxBase,nBaseSumAll := 0
Local cCntTp := "",cCntDoc := "",cIdObl := "",lFirsCnt := .F.,lCnt := .F.
Local nRet,cIdCard := "",RetValue,lR := .F.
Local cKOPNDS := Space(2),cKOPNNDS := Space(7),cKOPNDS0 := Space(7),cKOPAGNDS := Space(7)
Local cTaxModId := "", lRet := .T., aFinTax := {} // lTaxMod := .F. ,
/////////
Local oSum ,cAl,cAlTaxTp,cAlSprNds
Local nBaseSum := 0 // Сумма по документам по которым нет строк
Local cAlFinTax := "",lFinTax := .F. , cCom := "", cDop := ""
local cDocJrn, cDocDim := "", cSfDocDim, tb
local lAnalit := .F.,lSchet := .F. ,lFirst := .F. ,lFirstSch := .F.
local cAnalit := "",cSchet := ""
  begin sequence
  ::DelAllStr()
  if  nFor == 0
    cJrn := "PM01"
    StrTp := "0"
    cDocJrn := "DOCPM01"
  else
    cJrn := "PM02"
    StrTp := "1"
    cDocJrn := "DOCPM02"
  endif
  if Empty((::mAliasInv)->CNT_DOC_ID)
   lCnt := .T.
  endif

  if !(ValType(aLock) ==  "A")
    Break(.F.)
  endif

  if !Empty((::mAliasInv)->ACNT_ID) //.And. !Empty((::mAliasInv)->ANALIT)//Есть счет  и аналитика
    if (DIC_PLAN_SCH)->(DbSeek(Upper((::mAliasInv)->ACNT_ID)))
      lAnalit := (DIC_PLAN_SCH)->analit_y_n
    endif
  elseif Empty((::mAliasInv)->ACNT_ID) // счет нужно брать из документа
    lSchet := .T.  // перепишем счет из документов
  endif
  /////////////////////////*
  if lAnalit .Or. lSchet
    if ! _DbAreaOpen(B6_DBF_PATH + "PAY\DOC_CMP", @tb,"TAG_DOC")
      Break(.F.)
    endif
  endif

  if len(aLock) > 1
    //  Если  документов несколько проверим на соответствие
    // налоговых моделий
    for i := 1  to len(aLock)
      (oObjDoc)->(DbGoTo(aLock[i]))
      if !Empty((oObjDoc)->TAX_MOD_ID)
        if Empty(cTaxModId)
          if i == 1
            cTaxModId := (oObjDoc)->TAX_MOD_ID
          else
            Break(.F.)
          endif
        else
          if !(cTaxModId ==  (oObjDoc)->TAX_MOD_ID)
            Break(.F.)
          endif
        endif
      else
      // У предыдущего документа определена налоговая модель
        if  !Empty(cTaxModId)
          Break(.F.)
        endif
      endif

    next
  else
    (oObjDoc)->(DbGoTo(aLock[1]))
    if !Empty((oObjDoc)->TAX_MOD_ID)
      cTaxModId := (oObjDoc)->TAX_MOD_ID
    endif
  endif

  if !Empty(cTaxModId) .And. !(cTaxModId == (::cWa)->MOD_ID)
  // Переустановим налоговую модель
    oSum := ::TAX_STR:TAXSTRSUM
    cAl := oSum:mMODSTR
    cAlTaxTp :=  oSum:mTAX_TP
    cAlSprNds := oSum:mTbSprNds
    oSum:maModStr := {}
    if !CreateArModStr(@oSum:maModStr,cAl,cAlTaxTp,cAlSprNds,cTaxModId)
      Break(.F.)
    endif
    (::cWa)->MOD_ID :=  cTaxModId
    //lTaxMod := .T.
    // Если строк по налогам у документов нет - а налоговая модель есть
    // переустановим налоговую модель, а расчет
    // будем производить как и ранее
    /*
    if ! _DbAreaOpen(B6_DBF_PATH + "PAY\FIN_TAX.dbf", @cAlFinTax,"TAG_DOC")
      Break(.F.)
    endif
    for i := 1  to len(aLock)
      (oObjDoc)->(DbGoTo(aLock[i]))
      if (cAlFinTax)->(DbSeek((oObjDoc)->ROWID))
        AADD(aFinTax,{aLock[i],1})
      endif
    next
    */
  endif

  if ! _DbAreaOpen(B6_DBF_PATH + "PAY\FIN_TAX.dbf", @cAlFinTax,"TAG_DOC")
    Break(.F.)
  endif
  /*
  for i := 1  to len(aLock)
    (oObjDoc)->(DbGoTo(aLock[i]))
    if (cAlFinTax)->(DbSeek((oObjDoc)->ROWID))
      AADD(aFinTax,{aLock[i],1})
    endif
  next
  */
  ///////////////////////*/

  for i := 1 to len(aLock)
    (oObjDoc)->(DbGoTo(aLock[i]))
    cKey := (oObjDoc)->ROWID
    dDocDate := (oObjDoc)->OPER_DATE

    nTaxBase := (oObjDoc)->SUM
    if Empty(StrTran(cDocDim,"-",""))
      cDocDim := (oObjDoc)->DocDim
    endif
    if Empty(cDop) .And. ::mParamIni[_TAX_DOP_AV]
      cDop := (oObjDoc)->COMMENT
    endif

    if Empty(cCom) .And. ::mParamIni[_TAX_COM_AV]
      cCom := (oObjDoc)->COMMENT
    endif


    if !SumForAvans(@nTaxBase,cKey,dDocDate)
      Break(.F.)
    endif
    if nTaxBase = 0
      loop // для документов с 0 суммой записи не делаем
    endif
    if (cAlFinTax)->(DbSeek((oObjDoc)->ROWID))
      AADD(aFinTax,{aLock[i],1})
    endif
    // В платежах - не идентификатор документа основания, а идентификатор карточки для этого документа
    if (tb)->(DbSeek((oObjDoc)->ROWID))
      if i == 1
        cAnalit := (tb)->KORR_DIM
        cSchet := (tb)->KORR_ACNT
      else
        if !(cAnalit == (tb)->KORR_DIM) //аналитики разные
          lFirst := .T.
        endif
        if !(cSchet == (tb)->KORR_ACNT) //аналитики разные
          lFirstSch := .T.
        endif
      endif
    endif

    if Empty(cKOPNDS)
      cKOPNDS :=  (oObjDoc)->KOP_NDS
    endif
    if Empty(cKOPNNDS)
      cKOPNNDS :=  (oObjDoc)->KOP_NNDS
    endif
    if Empty(cKOPNDS0)
      cKOPNDS0 :=  (oObjDoc)->KOP_NDS0
    endif
    if Empty(cKOPAGNDS)
      cKOPAGNDS :=  (oObjDoc)->KOP_AG_NDS
    endif

    if i == 1
      if !Empty((oObjDoc)->ACNT_ID) .And. !((oObjDoc)->ACNT_TP  == "3")
        cIdCard := (oObjDoc)->ACNT_ID
        cCntTp := (oObjDoc)->ACNT_TP
        if (oObjDoc)->PRT_TP = "1"

          RetValue := {}
          if LookUpSeek("Ap\AP_Card.Dbf","TAG_ID",@lR,cIdCard,{"doc_id","jrn_id"},@RetValue)
            if lR
              if Empty(cCntTp)
                do case
                  case RetValue[2] $ "2051,2052"
                    cCntTp := "1"
                  case RetValue[2] == "1601"
                    cCntTp := "3"
                  case RetValue[2] $ "TV21,0503"
                    cCntTp := "2"
                 endcase
              endif
              if !(cCntTp == "3")
                cCntDoc := RetValue[1]
              endif
            else
              cCntDoc := ""
            endif
          else
            cCntDoc := ""
          endif
        else
          cCntDoc := "" //(oObjDoc)->ACNT_ID
        endif
        cIdObl := (oObjDoc)->ID_OBL
      endif
    else
      if Empty(cIdCard) //
        if !Empty((oObjDoc)->ACNT_ID)
          cIdCard := (oObjDoc)->ACNT_ID
          cCntTp := (oObjDoc)->ACNT_TP
          if (oObjDoc)->PRT_TP = "1"
            RetValue := {}
            if LookUpSeek("Ap\AP_Card.Dbf","TAG_ID",@lR,cIdCard,{"doc_id","jrn_id"},@RetValue)
              if lR
                cCntDoc := RetValue[1]
                if Empty(cCntTp)
                  do case
                    case RetValue[2] $ "2051,2052"
                      cCntTp := "1"
                    case RetValue[2] == "1601"
                      cCntTp := "3"
                    case RetValue[2] $ "TV21,0503"
                      cCntTp := "2"
                   endcase
                endif
              else
                cCntDoc := ""
              endif
            else
              cCntDoc := ""
            endif
          else
            cCntDoc := (oObjDoc)->ACNT_ID
          endif
          cIdObl := (oObjDoc)->ID_OBL
        endif
      else
        if !Empty((oObjDoc)->ACNT_ID)
          if !(cIdCard == (oObjDoc)->ACNT_ID) //документы основания разные
            lFirsCnt := .T.
          endif
        endif
      endif
    endif

    nTaxBase := nTaxBase * ::mMultyStorno
    nBaseSumAll := nBaseSumAll + nTaxBase
    lFinTax := .F.
    for n := 1 to len(aFinTax)
      if aLock[i] == aFinTax[n][1]
        lFinTax := .T.
        // Коэффициент пересчета налогов по строкам
        if  Round(nTaxBase,6) != Round((oObjDoc)->SUM,6)
          aFinTax[n][2] := nTaxBase/(oObjDoc)->SUM
        endif
        exit
      endif
    next
    if !lFinTax
      nBaseSum := nBaseSum + nTaxBase
    endif

    AADD(aSelectDoc,{(oObjDoc)->ROWID,(oObjDoc)->(RecNo())})

  next

  if nBaseSumAll = 0
    Break(.F.)
  endif

  if nBaseSum > 0

    if!::TAX_STR:BeforAppend(StrTp,.T.) //kostia ошибка 31170 передадим SrtTp  !::TAX_STR:BeforAppend("0",.T.)
      messagebox("Не удалось создать строку счета-фактуры!",TITLEAPP,48)
      Break(.F.)
    endif
    if !::TAX_STR:Append()
      messagebox("Не удалось создать строку счета-фактуры!",TITLEAPP,48)
      Break(.F.)
    endif
    if ::mParamIni[_TAX_NM_AV]
      (::mAliasStr)->NNAME := ::mParamIni[_TAX_NM_AV_TXT]
    else
      (::mAliasStr)->NNAME := (oObjDoc)->COMMENT
    endif
    (::mAliasStr)->STR_TP := StrTp
    (::mAliasStr)->STR_SRC := .T.
    ::TAX_STR:TAXSTRSUM:MoveFirst()
    ::TAX_STR:TAXSTRSUM:GetTaxSum(nBaseSum)
  endif
  ////////////////////////*
  oSum := ::TAX_STR:TAXSTRSUM
  for i := 1 to Len(aFinTax)
    (oObjDoc)->(DbGoTo(aFinTax[i][1]))
    cKey := (oObjDoc)->ROWID
    if Len(oSum:maModStr) == 1
      (cAlFinTax)->(OrdScope(0,cKey))
      (cAlFinTax)->(OrdScope(1,cKey))
      (cAlFinTax)->(DbGoTop())
      do while !(cAlFinTax)->(Eof())
        /*
        if!::TAX_STR:BeforAppend(StrTp,.T.) //kostia ошибка 31170 передадим SrtTp  !::TAX_STR:BeforAppend("0",.T.)
          messagebox("Не удалось создать строку счета-фактуры!",TITLEAPP,48)
          Break(.F.)
        endif
        if !::TAX_STR:Append()
          messagebox("Не удалось создать строку счета-фактуры!",TITLEAPP,48)
          Break(.F.)
        endif
        (::mAliasStr)->STR_TP := StrTp
        (::mAliasStr)->STR_SRC := .T.
        */
        if !AppendStrTax(::TAX_STR,::mAliasStr,StrTp)
          Break(.F.)
        endif
        if ::mParamIni[_TAX_NM_AV]
            (::mAliasStr)->NNAME := ::mParamIni[_TAX_NM_AV_TXT]
         else
            (::mAliasStr)->NNAME := (oObjDoc)->COMMENT
         endif
        ::TAX_STR:TAXSTRSUM:MoveFirst()
        cAl := ::TAX_STR:TAXSTRSUM:cWa
        //(cAl)->TAX_ID := (cAlFinTax)->TAX_ID
        //(cAl)->TAX_IDRT := (cAlFinTax)->TAX_IDRT
        //(cAl)->TAX_RATE := (cAlFinTax)->TAX_RATE
        //(cAl)->TAX_BASE := (cAlFinTax)->TAX_BASE
        //(cAl)->TAX_SUM := (cAlFinTax)->TAX_SUM
        //(cAl)->IS_HAND := (cAlFinTax)->IS_HAND
        if !WriteTaxFromFinDoc(cAl,cAlFinTax,aFinTax[i][2])
          Break(.F.)
        endif
        ::TAX_STR:CreateTaxForSTR(.T.)
        (cAlFinTax)->(DbSkip(1))
      enddo
    else
      if !CheckFinTax(cAlFinTax,cKey,oSum:maModStr,::TAX_STR,::mAliasStr,StrTp,aFinTax[i][2])
        Break(.F.)
      endif
    endif
  next
  ///////////////////////////*/
  if !::mlRePlaceMod .And. lCnt .And. !Empty(cCntDoc)
   if lFirsCnt
     nRet := messagebox("У документов разные документы основания." + chr(13) + chr(10) +;
                          "Перенести документ основания из первого документа?",TITLEAPP,36)
     if nRet == 6 //Да
       ::DS:FieldValue("CNT_TYPE",cCntTp)
       ::DS:FieldValue("CNT_DOC_ID",cCntDoc)
       ::DS:FieldValue("ID_OBL",cIdObl)
     endif
   else
     ::DS:FieldValue("CNT_TYPE",cCntTp)
     ::DS:FieldValue("CNT_DOC_ID",cCntDoc)
     ::DS:FieldValue("ID_OBL",cIdObl)
   endif
 endif
 if !Empty(StrTran(cDocDim,"-",""))
   cSfDocDim := (::cWa)->DocDim
   //if ExchangeCodeSegment(cDocJrn,cDocDim,"DOC1601",@cSfDocDim,.T.,.T.,.F.)
     (::cWa)->DocDim := grMaskReFill(cDocJrn,cDocDim,"DOC1601",cSfDocDim, .F.)//cSfDocDim
   //endif
 endif
 if !Empty(cDop)
   ::DS:FieldValue("COMPL_m",cDop)
 endif

 if !Empty(cCom)
   ::DS:FieldValue("COMMENT_M",cCom)
 endif

 if !Empty(cKOPNDS)
   (::mAliasInv)->KOP_NDS := cKOPNDS
 endif
 if !Empty(cKOPNNDS)
   (::mAliasInv)->KOP_NNDS := cKOPNNDS
 endif
 if !Empty(cKOPNDS0)
   (::mAliasInv)->KOP_NDS0 := cKOPNDS0
 endif
 if !Empty(cKOPAGNDS)
   (::mAliasInv)->KOP_AG_NDS := cKOPAGNDS
 endif

 if !::mlRePlaceMod .And. lSchet
   if lFirstSch
     nRet := messagebox("У документов разные корреспондирующие счета." + chr(13) + chr(10) +;
                        "Перенести в счет-фактуру счет из первого документа?",TITLEAPP,36)
     if nRet == 6 //Да
       ::DS:FieldValue("ACNT_ID",cSchet)
     else
       lAnalit := .F.
     endif
   else
     ::DS:FieldValue("ACNT_ID",cSchet)
   endif
   if (DIC_PLAN_SCH)->(DbSeek(Upper(cSchet)))
      lAnalit := (DIC_PLAN_SCH)->analit_y_n
   endif
 endif

 if !::mlRePlaceMod .And. lAnalit // Есть аналитика - может нужно переписать
   //Аналитики одинаковые ничего переписывать не нужно
   if lSchet
     if lFirst
       nRet := messagebox("У документов разные аналитические коды." + chr(13) + chr(10) +;
                          "Перенести в счет-фактуру аналитику из первого документа?",TITLEAPP,36)
       if nRet == 6 //Да
         ::DS:FieldValue("ANALIT",cAnalit)
       endif
     else
       ::DS:FieldValue("ANALIT",cAnalit)
     endif
   else
     if !Empty(cSchet) .And. (::mAliasInv)->ACNT_ID == cSchet
       if !(Upper(Alltrim(cAnalit)) ==  Upper(Alltrim((::mAliasInv)->ANALIT)))
         if lFirst
           nRet := messagebox("У документов разные аналитические коды." + chr(13) + chr(10) +;
                              "Перенести в счет-фактуру аналитику из первого документа?",TITLEAPP,36)
           if nRet == 6 //Да
             ::DS:FieldValue("ANALIT",cAnalit)
           endif
         else
           ::DS:FieldValue("ANALIT",cAnalit)
         endif
       endif
     elseif !Empty(cSchet) .And. !((::mAliasInv)->ACNT_ID == cSchet)
       if lFirst
         nRet := messagebox("У документов разные аналитические коды." + chr(13) + chr(10) +;
                            "Перенести в счет-фактуру аналитику из первого документа?",TITLEAPP,36)
         if nRet == 6 //Да
           //cAnalit := grMaskReMake(cSchet,cAnalit,(::mAliasInv)->ACNT_ID)
           cAnalit := grMaskReFill((::mAliasInv)->ACNT_ID,;
                                   (::mAliasInv)->ANALIT,;
                                   cSchet,;
                                   cAnalit,;
                                    .F.)
           ::DS:FieldValue("ANALIT",cAnalit)
         endif
       else
         //cAnalit := grMaskReMake(cSchet,cAnalit,(::mAliasInv)->ACNT_ID)
         cAnalit := grMaskReFill((::mAliasInv)->ACNT_ID,;
                                   (::mAliasInv)->ANALIT,;
                                   cSchet,;
                                   cAnalit,;
                                    .F.)
         ::DS:FieldValue("ANALIT",cAnalit)
       endif

     endif
   endif
 endif

  n := len(::aSfDoc)
  m := len(aSelectDoc)
  if n > 0 .And. cJrn ==  ::aSfDoc[1][_JRNID]
      lAdd := .T.

      for k := 1 to n
        for i := 1 to m
          if ::aSfDoc[k][_DOCID] == aSelectDoc[i][1]
             ::aSfDoc[k][_SFSTRID] := ::TAX_STR:STR_ID
             ::aSfDoc[k][_STATUS] := 0
             ::aSfDoc[k][_DEL] := .F.
             lAdd := .F.
          endif
        next
      next
      if lAdd
       cKey := cJrn+(oObjDoc)->ROWID+"1"
       AADD(::aSfDoc,{(::mAliasInv)->DOC_ID,;
                       ::TAX_STR:STR_ID,;
                       aSelectDoc[i][1] ,;
                       aSelectDoc[i][1] ,;
                       cJrn,;
                       .F.,;
                       1,cKey,aSelectDoc[i][2]})
      endif

  else
    n := len(aSelectDoc)
    for i := 1 to n
     cKey := cJrn+(oObjDoc)->ROWID+"1"
     AADD(::aSfDoc,{(::mAliasInv)->DOC_ID,;
                     ::TAX_STR:STR_ID,;
                     aSelectDoc[i][1] ,;
                     aSelectDoc[i][1] ,;
                     cJrn,;
                     .F.,;
                     1,cKey,aSelectDoc[i][2]})
    next
  endif
  recover using oErr
    lRet := .F.
  end sequence
  _DbAreaClose(cAlFinTax)
  _DbAreaClose(tb)
Return lRet

Method clsTax_Inv:CreateForDoc51Order(oObjDoc,nFor,aLock)
local  oErr
local tb,i,nTaxBase,StrTp
Local cAnalit := "",lAnalit := .F.,lFirst := .F. ,nRet
Local /*cAliasRecAp,cAliasShip,*/cKey,nSumReg := 0,nRate := 1,dDocDate
Local nSumRegCard := 0,cCurCard := ""
Local cValName := "",cValCode := "" //cAlSfDoc,
Local cSchet := "",lFirstSch := .F.,lSchet := .F.,nBaseSumAll := 0
Local aSelectDoc := {},n,k,m ,nJrn,lAdd
Local cTbName := "",cAlsPrm := "" ,aNds := {},cParamNDS := "",cParamSum :="",j
Local nSumAll := 0,nSumKalk := 0 ,aNdsAll := {}
Local aModStr := {} ,lNoNds := .T. ,cKeyKalk := ""
Local cCntTp := "",cCntDoc := "",cIdObl := "",lFirsCnt := .F.,lCnt := .F.
Local cDop := "" , cCom := ""
Local cKOPNDS := Space(2),cKOPNNDS := Space(7),cKOPNDS0 := Space(7),cKOPAGNDS := Space(7)
local cDocJrn , cDocDim := "", cSfDocDim
//altd()
 begin sequence
 StrTp := ""
 //удалим ссылки на документы
 ::DelAllStr()

 tb := oObjDoc //:Alias //::tbDoc
 if Empty((::mAliasInv)->CNT_DOC_ID)
   lCnt := .T.
 endif
 if !Empty((::mAliasInv)->ACNT_ID) //.And. !Empty((::mAliasInv)->ANALIT)//Есть счет  и аналитика
   if (DIC_PLAN_SCH)->(DbSeek(Upper((::mAliasInv)->ACNT_ID)))
      lAnalit := (DIC_PLAN_SCH)->analit_y_n
   endif
 elseif Empty((::mAliasInv)->ACNT_ID) // счет нужно брать из документа
   lSchet := .T.  // перепишем счет из документов
 endif
 for i := 1 to len(aLock)
   //altd()
   (tb)->(DbGoTo(aLock[i]))

       do case
         case nFor == 0
           cValName := "valuta"
           nJrn := "0101"
           cTbName := "Bank\kalk_d_b.dbf"
           cParamNDS := "NDS"
           cParamSum := "R1"
           if i == 1
             cAnalit := (tb)->Scr
             cSchet := (tb)->cr
           else
             if !(cAnalit == (tb)->Scr) //аналитики разные
               lFirst := .T.
             endif
             if !(cSchet == (tb)->cr) //аналитики разные
               lFirstSch := .T.
             endif
           endif

         case nFor == 1
           cValName := "code_curr"
           nJrn := "0201"
           cTbName := "Cash\kalk_d_k.dbf"
           cParamNDS := "NDS_18"
           cParamSum := "S_NDS18"

           if i == 1
             cAnalit := (tb)->An_KSchet
             cSchet := (tb)->kschet
           else
             if !(cAnalit == (tb)->An_KSchet)
               lFirst := .T.
             endif
             if !(cSchet == (tb)->kschet) //аналитики разные
               lFirstSch := .T.
             endif
           endif
       endcase
       cDocJrn := "Doc" + nJrn
       if Empty(StrTran(cDocDim,"-",""))
         cDocDim := (tb)->DocDim
       endif
       if Empty(cDop) .And. ::mParamIni[_TAX_DOP_AV]
         if nFor == 0
           cDop := (tb)->NAME
         else
           cDop := (tb)->REASON
         endif
       endif

       if Empty(cCom) .And. ::mParamIni[_TAX_COM_AV]
         if nFor == 0
           cCom := (tb)->NAME
         else
           cCom := (tb)->REASON
         endif
       endif
 /*
       #define _TAX_NM_AV      18 // T - из документа  Наименование авансового счета-фактуры
#define _TAX_NM_AV_TXT  19 // Текст наименования
#define _TAX_DOP_AV     20 // T - из документа  Дополнение авансового счета-фактуры
#define _TAX_COM_AV
 */

       if i == 1
         if !Empty((tb)->CNT_DOC_ID) .And.  !((tb)->CNT_TYPE == "3")
           cCntTp := (tb)->CNT_TYPE
           cCntDoc := (tb)->CNT_DOC_ID
           cIdObl := (tb)->ID_OBL
         endif
       else
         if Empty(cCntDoc) //
           if !Empty((tb)->CNT_DOC_ID) .And.  !((tb)->CNT_TYPE == "3")
             cCntTp := (tb)->CNT_TYPE
             cCntDoc := (tb)->CNT_DOC_ID
             cIdObl := (tb)->ID_OBL
           endif
         else
           if !Empty((tb)->CNT_DOC_ID)
             if !(cCntDoc == (tb)->CNT_DOC_ID) //документы основания разные
               lFirsCnt := .T.
             endif
           endif
         endif
       endif

       if ! _DbAreaOpen(B6_DBF_PATH + cTbName, @cAlsPrm,"TAG_PAR")
          Break(.F.)
       endif


       // проверяем валюты
     if nFor == 0
       StrTp := "0"
       cKey := (tb)->NNOPER_ID
       dDocDate := (tb)->DOPER
       cKeyKalk :=  (tb)->oper_kalk
     else
       StrTp := "1"
       cKey := (tb)->NNOPER
       dDocDate := (tb)->DATAOPER
       cKeyKalk :=  (tb)->oper_kalk
     endif
     nTaxBase := (tb)->SUMMA
     nSumAll := (tb)->SUMMA
     if !SumForAvans(@nTaxBase,cKey,dDocDate)
       Break(.F.)
     endif

     if Empty(cKOPNDS)
       cKOPNDS :=  (tb)->KOP_NDS
     endif
     if Empty(cKOPNNDS)
       cKOPNNDS :=  (tb)->KOP_NNDS
     endif
     if Empty(cKOPNDS0)
       cKOPNDS0 :=  (tb)->KOP_NDS0
     endif
     if Empty(cKOPAGNDS)
       cKOPAGNDS :=  (tb)->KOP_AG_NDS
     endif

     if nTaxBase = 0
       loop // ?для документов с 0 суммой записи не делаем
     endif

     aNds := {}
     if !CreateArrayTaxForDocOldPay(cAlsPrm,cKeyKalk,cParamNDS,cParamSum,@aNds)
       Break(.F.)
     endif
     /*
     if (cAlsPrm)->(DbSeek(cKeyKalk + Padr("O_NDS18",10)))
       if !Empty((cAlsPrm)->znahen)
         nSumKalk := nSumKalk + (cAlsPrm)->znahen
         AADD(aNds,{18,,0,(cAlsPrm)->znahen,.F.})
         j := len(aNds)
         if (cAlsPrm)->(DbSeek(cKeyKalk + Padr(cParamNDS,10)))
           if (cAlsPrm)->znahen == 18
             aNds[j][2] := 18
           endif
         endif
         if (cAlsPrm)->(DbSeek(cKeyKalk + Padr(cParamSum,10)))
           aNds[j][3] := (cAlsPrm)->znahen
         endif
       endif
     endif
     if (cAlsPrm)->(DbSeek(cKeyKalk + Padr("O_NDS10",10)))
       if !Empty((cAlsPrm)->znahen)
         nSumKalk := nSumKalk + (cAlsPrm)->znahen
         AADD(aNds,{10,,0,(cAlsPrm)->znahen,.F.})
         j := len(aNds)
         if (cAlsPrm)->(DbSeek(cKeyKalk + Padr("NDS_10",10)))
           if (cAlsPrm)->znahen == 10
             aNds[j][2] := 10
           endif
         endif
         if (cAlsPrm)->(DbSeek(cKeyKalk + Padr("S_NDS10",10)))
           aNds[j][3] := (cAlsPrm)->znahen
         endif
       endif
     endif
     if (cAlsPrm)->(DbSeek(cKeyKalk + Padr("O_NDS0",10)))
       if !Empty((cAlsPrm)->znahen)
         nSumKalk := nSumKalk + (cAlsPrm)->znahen
         AADD(aNds,{0,,0,(cAlsPrm)->znahen,.F.})
         j := len(aNds)
         if (cAlsPrm)->(DbSeek(cKeyKalk + Padr("NDS_0",10)))
           if (cAlsPrm)->znahen == 0
             aNds[j][2] := 0
           endif
         endif
         if (cAlsPrm)->(DbSeek(cKeyKalk + Padr("S_NDS0",10)))
           aNds[j][3] := (cAlsPrm)->znahen
         endif
       endif
     endif
     if (cAlsPrm)->(DbSeek(cKeyKalk + Padr("O_NDSN",10)))
       if !Empty((cAlsPrm)->znahen)
         nSumKalk := nSumKalk + (cAlsPrm)->znahen
         AADD(aNds,{0,,0,(cAlsPrm)->znahen,.T.})
         j := len(aNds)
         if (cAlsPrm)->(DbSeek(cKeyKalk + Padr("NDS_N",10)))
           if (cAlsPrm)->znahen == 0
             aNds[j][2] := 0
           endif
         endif
         if (cAlsPrm)->(DbSeek(cKeyKalk + Padr("S_NDSN",10)))
           aNds[j][3] := (cAlsPrm)->znahen
         endif
       endif
     endif
     */
     if len(aNds) > 0 //nSumKalk > 0
      /*
       if nSumAll > nSumKalk
         k := nSumKalk/nSumAll
       else
         k := 1
       endif
      */
       if nTaxBase < nSumAll
         k := nTaxBase/nSumAll
       else
         k := 1
       endif

       nTaxBase := 0
       for j := 1 to len(aNds)
         aNds[j][3] := BS_ROUND(aNds[j][3] * k,::mRound)* ::mMultyStorno
         aNds[j][4] := BS_ROUND(aNds[j][4] * k,::mRound)* ::mMultyStorno
         aadd(aNdsAll,aNds[j])
       next
     endif

     nTaxBase := nTaxBase * ::mMultyStorno
     nBaseSumAll := nBaseSumAll + nTaxBase

      if nFor == 0
        AADD(aSelectDoc,{(tb)->NNOPER_ID,(tb)->(RecNo())})
      else
        AADD(aSelectDoc,{(tb)->NNOPER,(tb)->(RecNo())})
      endif


 next
 if nBaseSumAll = 0 .And. (len(aNdsAll) < 1 )
   Break(.F.)
 endif
 aModStr := ::TAX_STR:TAXSTRSUM:maModStr
 if len(aModStr) = 1 .And. AllTrim(aModStr[1][_SYSNUM]) == "1"
   messagebox("Налоговая модель счета-фактуры не совпадает с налоговыми данными документа." + chr(13) + chr(10) + ;
              "Создание счета-фактуры невозможно",TITLEAPP,48)
   Break(.F.)
 endif
 if nBaseSumAll > 0
   if!::TAX_STR:BeforAppend(StrTp,.T.) //kostia ошибка 31170 передадим SrtTp  !::TAX_STR:BeforAppend("0",.T.)
     messagebox("Не удалось создать строку счета-фактуры!",TITLEAPP,48)
     Break(.F.)
   endif
   if !::TAX_STR:Append()
     messagebox("Не удалось создать строку счета-фактуры!",TITLEAPP,48)
     Break(.F.)
   endif

   if ::mParamIni[_TAX_NM_AV]
     (::mAliasStr)->NNAME := ::mParamIni[_TAX_NM_AV_TXT]
   else
     if nFor == 0
        (::mAliasStr)->NNAME := (tb)->NAME
     else
        (::mAliasStr)->NNAME := (tb)->REASON
     endif

   endif
   (::mAliasStr)->STR_TP := StrTp
   (::mAliasStr)->STR_SRC := .T.
   ::TAX_STR:TAXSTRSUM:MoveFirst()
   ::TAX_STR:TAXSTRSUM:GetTaxSum(nBaseSumAll)
 endif


 for i := 1 to len(aNdsAll)
   if !::TAX_STR:BeforAppend(StrTp,.T.) //!::TAX_STR:BeforAppend("0",.T.)
     messagebox("Не удалось создать строку счета-фактуры!",TITLEAPP,48)
     Break(.F.)
   endif
   if !::TAX_STR:Append()
     messagebox("Не удалось создать строку счета-фактуры!",TITLEAPP,48)
     Break(.F.)
   endif
   if ::mParamIni[_TAX_NM_AV]
     (::mAliasStr)->NNAME := ::mParamIni[_TAX_NM_AV_TXT]
   else
     if nFor == 0
        (::mAliasStr)->NNAME := (tb)->NAME
     else
        (::mAliasStr)->NNAME := (tb)->REASON
     endif

   endif
   (::mAliasStr)->STR_TP := StrTp
   (::mAliasStr)->STR_SRC := .T.
   ::TAX_STR:TAXSTRSUM:MoveFirst()
   if len(aModStr) = 1 // Налог 1 и это НДС
     if !::ReplaceNdsFromKalk(aNdsAll[i])
       Break(.F.)
     endif

   else
     if AllTrim(aModStr[1][_SYSNUM]) == "1"  // Первый акциз
       // Посчитаем по налоговой модели - а потом поменяем НДС
       if aModStr[1][_CALCRL] // извлекается
         nBaseSumAll := aNdsAll[i][4]
       else
         nBaseSumAll := aNdsAll[i][4] - aNdsAll[i][3]
       endif
       ::TAX_STR:TAXSTRSUM:GetTaxSum(nBaseSumAll)
       ::TAX_STR:TAXSTRSUM:MoveFirst()
       k := 1
       Do While !::TAX_STR:TAXSTRSUM:Eof
         if ::TAX_STR:TAXSTRSUM:TAX_ID == aModStr[k][_TAXID] .And. AllTrim(aModStr[k][_SYSNUM]) == "2"
         // стали на строку НДС
           if !::ReplaceNdsFromKalk(aNdsAll[i])
             Break(.F.)
           endif

         endif
         k += 1
         ::TAX_STR:TAXSTRSUM:Skip(1)
       enddo
     else
     // Первый НДС
       if !::ReplaceNdsFromKalk(aNdsAll[i])
         Break(.F.)
       endif
       if aModStr[1][_MODBS]
         if aModStr[1][_CALCRL]
           nBaseSumAll := (::mAliasSum)->TAX_BASE - (::mAliasSum)->TAX_SUM
         else
           nBaseSumAll := (::mAliasSum)->TAX_BASE + (::mAliasSum)->TAX_SUM
         endif
       else
         nBaseSumAll := (::mAliasSum)->TAX_BASE
       endif
       ::TAX_STR:TAXSTRSUM:Skip(1)
       if !::TAX_STR:TAXSTRSUM:Eof
         ::TAX_STR:TAXSTRSUM:GetTaxSum(nBaseSumAll,,,::TAX_STR:TAXSTRSUM:RecNo())
       endif
     endif

     /*
     if ::TAX_STR:TAXSTRSUM:maModStr[1][_CALCRL] // Извлекаем
       nBaseSumAll := aNdsAll[i][4]
     else

     endif
     ::TAX_STR:TAXSTRSUM:GetTaxSum(nBaseSumAll)
     */
   endif
 next
 if !Empty(StrTran(cDocDim,"-",""))
     cSfDocDim := (::cWa)->DocDim
     //if ExchangeCodeSegment(cDocJrn,cDocDim,"DOC1601",@cSfDocDim,.T.,.T.,.F.)
       (::cWa)->DocDim := grMaskReFill(cDocJrn,cDocDim,"DOC1601",cSfDocDim, .T.)//cSfDocDim
     //endif
  endif

 if !Empty(cDop)
   ::DS:FieldValue("COMPL_m",cDop)
 endif

 if !Empty(cCom)
   ::DS:FieldValue("COMMENT_M",cCom)
 endif

 /*
 if  !((::mAliasInv)->STR_TP == StrTp)
    ::DS:FieldValue("STR_TP", StrTp) // есть записи созданные из платежек
 endif
 */
 n := len(::aSfDoc)
 m := len(aSelectDoc)
 if n > 0 .And. nJrn ==  ::aSfDoc[1][_JRNID]
      lAdd := .T.

      for k := 1 to n
        for i := 1 to m
          if ::aSfDoc[k][_DOCID] == aSelectDoc[i][1]
             ::aSfDoc[k][_SFSTRID] := ::TAX_STR:STR_ID
             ::aSfDoc[k][_STATUS] := 0
             ::aSfDoc[k][_DEL] := .F.
             lAdd := .F.
          endif
        next
      next
      if lAdd

       if nFor == 0
         cKey := nJrn+(tb)->NNOPER_ID+"1"
       else
         cKey := nJrn+(tb)->NNOPER+"1"
       endif

       AADD(::aSfDoc,{(::mAliasInv)->DOC_ID,;
                       ::TAX_STR:STR_ID,;
                       aSelectDoc[i][1] ,;
                       aSelectDoc[i][1] ,;
                       nJrn,;
                       .F.,;
                       1,cKey,aSelectDoc[i][2]})
      endif

 else
   n := len(aSelectDoc)
   for i := 1 to n

     if nFor == 0
       cKey := nJrn+(tb)->NNOPER_ID+"1"
     else
       cKey := nJrn+(tb)->NNOPER+"1"
     endif

     AADD(::aSfDoc,{(::mAliasInv)->DOC_ID,;
                     ::TAX_STR:STR_ID,;
                     aSelectDoc[i][1] ,;
                     aSelectDoc[i][1] ,;
                     nJrn,;
                     .F.,;
                     1,cKey,aSelectDoc[i][2]})
   next
 endif


 if !::mlRePlaceMod .And. lCnt .And. !Empty(cCntDoc)
   if lFirsCnt
     nRet := messagebox("У документов разные документы основания." + chr(13) + chr(10) +;
                          "Перенести документ основания из первого документа?",TITLEAPP,36)
     if nRet == 6 //Да
       ::DS:FieldValue("CNT_TYPE",cCntTp)
       ::DS:FieldValue("CNT_DOC_ID",cCntDoc)
       ::DS:FieldValue("ID_OBL",cIdObl)
     endif
   else
     ::DS:FieldValue("CNT_TYPE",cCntTp)
     ::DS:FieldValue("CNT_DOC_ID",cCntDoc)
     ::DS:FieldValue("ID_OBL",cIdObl)
   endif
 endif
 if !::mlRePlaceMod .And. lSchet
   if lFirstSch
     nRet := messagebox("У документов разные корреспондирующие счета." + chr(13) + chr(10) +;
                        "Перенести в счет-фактуру счет из первого документа?",TITLEAPP,36)
     if nRet == 6 //Да
       ::DS:FieldValue("ACNT_ID",cSchet)
     else
       lAnalit := .F.
     endif
   else
     ::DS:FieldValue("ACNT_ID",cSchet)
   endif
   if (DIC_PLAN_SCH)->(DbSeek(Upper(cSchet)))
      lAnalit := (DIC_PLAN_SCH)->analit_y_n
   endif
 endif
 if !::mlRePlaceMod .And. lAnalit // Есть аналитика - может нужно переписать
   //Аналитики одинаковые ничего переписывать не нужно
   if lSchet
     if lFirst
       nRet := messagebox("У документов разные аналитические коды." + chr(13) + chr(10) +;
                          "Перенести в счет-фактуру аналитику из первого документа?",TITLEAPP,36)
       if nRet == 6 //Да
         ::DS:FieldValue("ANALIT",cAnalit)
       endif
     else
       ::DS:FieldValue("ANALIT",cAnalit)
     endif
   else
     if !Empty(cSchet) .And. (::mAliasInv)->ACNT_ID == cSchet
       if !(Upper(Alltrim(cAnalit)) ==  Upper(Alltrim((::mAliasInv)->ANALIT)))
         if lFirst
           nRet := messagebox("У документов разные аналитические коды." + chr(13) + chr(10) +;
                              "Перенести в счет-фактуру аналитику из первого документа?",TITLEAPP,36)
           if nRet == 6 //Да
             ::DS:FieldValue("ANALIT",cAnalit)
           endif
         else
           ::DS:FieldValue("ANALIT",cAnalit)
         endif
       endif
     elseif !Empty(cSchet) .And. !((::mAliasInv)->ACNT_ID == cSchet)
       if lFirst
         nRet := messagebox("У документов разные аналитические коды." + chr(13) + chr(10) +;
                            "Перенести в счет-фактуру аналитику из первого документа?",TITLEAPP,36)
         if nRet == 6 //Да
           //cAnalit := grMaskReMake(cSchet,cAnalit,(::mAliasInv)->ACNT_ID)
           cAnalit := grMaskReFill((::mAliasInv)->ACNT_ID,;
                                   (::mAliasInv)->ANALIT,;
                                   cSchet,;
                                   cAnalit,;
                                    .F.)
           ::DS:FieldValue("ANALIT",cAnalit)
         endif
       else
         //cAnalit := grMaskReMake(cSchet,cAnalit,(::mAliasInv)->ACNT_ID)
         cAnalit := grMaskReFill((::mAliasInv)->ACNT_ID,;
                                   (::mAliasInv)->ANALIT,;
                                   cSchet,;
                                   cAnalit,;
                                    .F.)
         ::DS:FieldValue("ANALIT",cAnalit)
       endif

     endif
   endif
 endif

 if !Empty(cKOPNDS)
   (::mAliasInv)->KOP_NDS := cKOPNDS
 endif
 if !Empty(cKOPNNDS)
   (::mAliasInv)->KOP_NNDS := cKOPNNDS
 endif
 if !Empty(cKOPNDS0)
   (::mAliasInv)->KOP_NDS0 := cKOPNDS0
 endif
 if !Empty(cKOPAGNDS)
   (::mAliasInv)->KOP_AG_NDS := cKOPAGNDS
 endif

 tb := nil
 //_DbAreaClose(cAliasRecAp)
 //_DbAreaClose(cAliasShip)
 _DbAreaClose(cAlsPrm)
 recover using oErr
  //_DbAreaClose(cAliasRecAp)
  //_DbAreaClose(cAliasShip)
  _DbAreaClose(cAlsPrm)
  tb := Nil
  if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence

Return .T.

Method clsTax_Inv:RegDocForSF()
Local nTypeAp,nVid,cPartner,cBrg,cApCard
Local cDocId,nJrn,cSchetDoc,obj,DocDate,cDocCurCode,nSum
local oErr,cTagName := "" ,lStorno,/*i,*/cVidDoc,cNumDoc
local i,n , dDateUr,nDocRate //dbSfDoc,cAlSfDoc,
  begin sequence
  //dbSfDoc := ::SFDOC:DS
  //cAlSfDoc := dbSfDoc:Alias()
  //dbSfDoc:SetOrder("TAG_SFDOC")
  //dbSfDoc:Scope((::mAliasInv)->DOC_ID,(::mAliasInv)->DOC_ID,"TAG_SFDOC")
  //dbSfDoc:GoTop()
  n := len(::aSfDoc)
  if n < 1
    Break(.T.)
  endif
  cSchetDoc := (::mAliasInv)->ACNT_ID
  cPartner := (::mAliasInv)->PRT_ID
  nTypeAp := val((::mAliasInv)->TI_CTG)
  cBrg := (::mAliasInv)->DOC_ID
  cApCard := ::mCardId
  //Do While !dbSfDoc:Eof()

  for i := 1 to n
    if ::aSfDoc[i][_DEL] .Or. !(::aSfDoc[i][_DOCID] == ::aSfDoc[i][_DOCSTRID])
      Loop
    endif
    //if (cAlSfDoc)->DOC_ID == (cAlSfDoc)->DOCSTR_ID // документ а не строка документа
      cDocId := ::aSfDoc[i][_DOCID]//(cAlSfDoc)->DOC_ID
      nJrn := ::aSfDoc[i][_JRNID]//(cAlSfDoc)->JRN_ID
      if ValType(obj) == "O"
        obj:Destroy()
        obj := nil
      endif
      do case
      /*  22989 - платежи не регистрим
        case nJrn == 101
          obj := clsTaxForDoc51():New()
          cTagName := "TAG_OPER"
        case nJrn == 201
          obj := clsTaxForK_ORDER():New()
          cTagName := "TAG_OPER"
        case nJrn == 203
        */
        case nJrn == "0301"
          obj := clsTaxForMDoc():New()
          cTagName := "TAG_OPER"
        case nJrn == "0501"
          obj := clsTaxForRealAct():New()
          cTagName := "TAG_OPER"
        case nJrn == "0901"
          obj := clsTaxForZapasMDoc():New()
          cTagName := "TAG_OPER"
        case nJrn == "TV01" //1201
          obj := clsTaxForTovarAct():New()
          cTagName := "TAG_OPER"
        case nJrn == "1701"
          obj := clsTaxForAssets():New()
          cTagName := "TAG_ID"
      endcase
      obj:Open()
      if !obj:Seek(cDocId,.T.,cTagName)
      // !!!!!
        //dbSfDoc:Skip(1)
        Loop
      endif
      nVid        := obj:SRC_VID
      DocDate     := obj:SRC_DATE
      cDocCurCode := ::mMainCurCode //obj:SRC_VCODE

      //nSum        := obj:SRC_SUMALL //SRC_SUMMAV
      nSum        := obj:SRC_DOC
      lStorno     := obj:SRC_STORNO
      cVidDoc     := obj:SRC_TP
      cNumDoc     := obj:SRC_NUM
      if nJrn $ "0301,0901,0904,AS01"
        dDateUr := (obj:Alias)->DATEDOCP
        cDocCurCode := (obj:Alias)->CODEVAL
        nDocRate   := (obj:Alias)->CENAVAL
      endif
      if nJrn $ "0501,TV01"
        cDocCurCode :=  (obj:Alias)->CODEVAL
        nDocRate   := (obj:Alias)->CURS
      endif
      //                1    2    3
      if !RegDocForAp(nJrn,cDocId,2,;
                    ;// 4     5      6       7
                     nTypeAp,nVid,cPartner,cBrg,;
                     ;// 8        9       10     11      12
                     DocDate,cDocCurCode,nSum,cApCard,lStorno,;
                     ;// 13     14
                     cVidDoc,cNumDoc,;
                     ;//   16           17 18 19 20 21 22 23       24       25  26     27   28
                     ,::mTbApReg,::mTbCard,  ,  ,  ,  ,  ,  , obj:SRC_URNUM,  ,dDateUr, ,nDocRate)

        /*   22989 - платежи не регистрим
        if nJrn $ { 101,201 } // 22974 - проставим идентификатор с-ф в документ основание
          For i := 1 to len(::maTbDoc)
            if nJrn == ::maTbDoc[i][1]
              if ::maTbDoc[i][2]:Seek(cDocId,.T.,"TAG_OPER")
                ::maTbDoc[i][2]:FieldValue("cnt_doc_id",::SFDOC:sf_id)
                ::maTbDoc[i][2]:FieldValue("cnt_type","3")
              endif
            endif
          next
        endif
        */
        Break(.F.)
      endif

    //endif
  //  dbSfDoc:Skip(1)
  //Enddo
  next
  if ValType(obj) == "O"
        obj:Destroy()
        obj := nil
  endif
  recover using oErr
    if ValType(obj) == "O"
        obj:Destroy()
        obj := nil
     endif
    if valtype(oErr) == "L"
      return oErr
    else
      return .F.
    endif
  end sequence
Return .T.

// Блокируем записи выбранных документов
// разблокируем остальные, кроме тех которые брали на редактирование
Method clsTax_Inv:ReLockDocForSf(nJrn,aParam)
  local oErr,i,n,j
  begin sequence

  for i := 1 to Len(::maTbDoc)
    for n := 1 to len(::maTbDoc[i][4])
      if AScan(::maTbDoc[i][3], ::maTbDoc[i][4][n]) < 1
        (::maTbDoc[i][2])->(DbGoTo(::maTbDoc[i][4][n]))
        (::maTbDoc[i][2])->(DbRUnLock(::maTbDoc[i][4][n]))
      endif
    next
    ::maTbDoc[i][4] := {}
    if nJrn == ::maTbDoc[i][1]
      for j := 1 to len(aParam)
        (::maTbDoc[i][2])->(DbGoTo(aParam[j]))
        if (::maTbDoc[i][2])->(DbRLock(aParam[j]))
          AADD(::maTbDoc[i][4],aParam[j])
        else
          messagebox("Документ-источник редактируется.",TITLEAPP,48)
          Break(.F.)
        endif
      next

    endif

  next

  recover using oErr
    if valtype(oErr) == "L"
      return oErr
    else
      return .F.
    endif
  end sequence
Return .T.

*
*                     востановление аннулированных записей
* Восстановить аннулированные  записи - можно по текущему счету-фактуре.
* При этом дата и номер доп листа  очищаются. Восстановить записи
* по счету-фактуре можно только в том случае, если по нему нет
* других, не аннулированных записей, при этом восстанавливаются
* все записи сразу.
*
* 43544 - Аннулирование записей доп.листов (корректировочных).

Method clsTax_Inv:RecoverAnulRecords(lNoDoc)
  local dsSF, dsBook,dsBookSt, nRecNo, nRecNoSt
  local oErr, cMsg
  local lSfOld := .F., lRet := .F., bErr
  Local aDopLst := {"","",CTOD("")}
  Local lDiffer := .F. ,r := 0
*  local nRate
*  local a,n,i, nRecTax, oBkTax, x
  if ValType(lNoDoc) != "L"
    lNoDoc := .T.
  endif
  if ::EditMode != 0
    ::Cancel()
  endif
  if !::DS:Lock()
    return .f.
  endif
  cMsg := ""
  bErr := ErrorBlock({ |e| break( e ) })
  begin sequence
  *
    dsSF   := ::DS
    dsBook := ::BOOK:DS
    nRecNo := dsBook:RecNo
    dsBook:GoTop()
    if dsBook:Eof
      break( 0 )
    endif
    dsBookSt := ::BOOKST:DS
    nRecNoSt := dsBookSt:RecNo
    *check before recovery
    do while !dsBook:Eof
      if !( dsBook:FieldValue("CMP_TP") $ "1,3" )
        cMsg := "Восстановить записи по счету-фактуре можно"+CRLF+;
                "только в том случае, если по нему нет других,"+CRLF+;
                "не аннулированных записей."
        break( 1 )
      else
        if Empty(aDopLst[1])
          aDopLst[1] := dsBook:FieldValue("CMP_TP")
          aDopLst[2] := dsBook:FieldValue("LST_NUM")
          aDopLst[3] := dsBook:FieldValue("LST_DATE")
        else
          if  aDopLst[1] != dsBook:FieldValue("CMP_TP") .Or. ;
              aDopLst[2] != dsBook:FieldValue("LST_NUM") .Or. ;
              aDopLst[3] != dsBook:FieldValue("LST_DATE")
            lDiffer := .T.
          endif
        endif
      endif
      if !dsBook:Lock()
        break( 0 )
      endif
      dsBook:skip(1)
    enddo
    aDopLst := {"","",CTOD("")}
    do while !dsBookSt:Eof
      if !( dsBookSt:FieldValue("CMP_TP") $ "1,3" )
        cMsg := "Восстановить записи по счету-фактуре можно"+CRLF+;
                "только в том случае, если по нему нет других,"+CRLF+;
                "не аннулированных записей."
        break( 1 )
      else
        if Empty(aDopLst[1])
          aDopLst[1] := dsBookSt:FieldValue("CMP_TP")
          aDopLst[2] := dsBookSt:FieldValue("LST_NUM")
          aDopLst[3] := dsBookSt:FieldValue("LST_DATE")
        else
          if  aDopLst[1] != dsBookSt:FieldValue("CMP_TP") .Or. ;
              aDopLst[2] != dsBookSt:FieldValue("LST_NUM") .Or. ;
              aDopLst[3] != dsBookSt:FieldValue("LST_DATE")
            lDiffer := .T.
          endif
        endif
      endif
      if !dsBookSt:Lock()
        break( 0 )
      endif
      dsBookSt:skip(1)
    enddo

    *если все записи в книге аннулированы, то и в этих полях 0
    dsSF:FieldValue("Sum_Book", 0)
    dsSF:FieldValue("Sum_PAY" , 0)
    dsSF:FieldValue("Sum_Shp" , 0)
    dsSF:FieldValue("St_Sum" , 0)
    //dsSF:FieldValue("Sum_Use" , 0)

    if lDiffer
      cMsg := "Записи по данному счету-фактуре " + chr(13) + chr(10) + ;
              "аннулировались неоднократно. " + chr(13) + chr(10) + ;
              "Восстановить все аннулированные записи? "

      r :=messagebox(cMsg,TITLEAPP,36)
      if !(r == 6)
        Break(.F.)
      endif
    endif

    dsBook:GoTop()
    do while !dsBook:Eof
      ::BOOK:RestoreAnulRecord( self,lNoDoc/*dsSF*/ )
      dsBook:skip(1)
    enddo
    dsBookSt:GoTop()
    ::DS:UnLock()
    do while !dsBookSt:Eof
      ::BOOKST:RestoreAnulRecord( ::BOOKST:SF,lNoDoc /*:DS*/ )
      dsBookSt:skip(1)
    enddo
    ::DS:Lock()
    dsSF:FieldValue("IS_ANUL", .F.)
    dsBook:GoTop()
    do while !dsBook:Eof
      if ::BOOK:CMP_TP $ "1,3"
        dsSF:FieldValue("IS_ANUL", .T.)
        //exit
      endif
      dsBook:skip(1)
    enddo
    dsBookSt:GoTop()
    do while !dsBookSt:Eof
      if ::BOOKST:CMP_TP $ "1,3"
        dsSF:FieldValue("IS_ANUL", .T.)
        //exit
      endif
      dsBookSt:skip(1)
    enddo

    lRet := .t.
  *
  recover using oErr
    if valtype(oErr) == "O"
      ErrorHandler(oErr)
    elseif valtype(oErr)=="N"
      do case
        case oErr == 1 .and. !Empty(cMsg)
          messagebox(cMsg,TITLEAPP,48)
      endcase
    endif
  end sequence
  *
  begin sequence
    dsBook:GoTop()
    do while !dsBook:Eof
      dsBook:UnLock()
      dsBook:skip(1)
    enddo

    dsBookSt:GoTop()
    do while !dsBookSt:Eof
      dsBookSt:UnLock()
      dsBookSt:skip(1)
    enddo

    ::DS:UnLock()
    dsSF:= nil
    dsBook:GoTo(nRecNo)
    dsBook:= nil
    dsBookSt:GoTo(nRecNoSt)
    dsBookSt:= nil

  recover using oErr
    if valtype(oErr) == "O"
      ErrorHandler(oErr)
    endif
  end sequence
  ErrorBlock( bErr )
return .t.


Method clsTax_Inv:CreateBrg(cCnt)
  local oErr
  Local aFile := {{"CNTR\CONTRACT.dbf", "TAG_OPER"},;
                  {"REAL\RBOOK.Dbf","TAG_OPER"},;
                  {"TOVAR\RBOOK.Dbf","TAG_OPER"}}
  Local tb,cTag
  begin sequence
  if cCnt == "1"
    tb := CreateDbRecord(B6_DBF_PATH + aFile[1][1])
    cTag := aFile[1][2]
    tb:SetOrder(cTag)
  elseif cCnt == "2"
     if (::mAliasInv)->TI_CTG == "1"   //покупки
       tb := CreateDbRecord(B6_DBF_PATH + aFile[3][1])
     else  //продажи
       tb := CreateDbRecord(B6_DBF_PATH + aFile[2][1])
     endif
     cTag := aFile[1][2]
     tb:SetOrder(cTag)
  endif
  AADD(::aTabCnt,{cCnt,tb,cTag})
  tb := nil
  recover using oErr
    tb := nil
    if valtype(oErr) == "L"
      return oErr
    else
      return .F.
    endif

  end sequence
Return .T.

Method clsTax_Inv:GetBrg(nParam)
Static cCnt := ""
Static cCntDocId := ""
Static cVidDoc := "",cNumDoc := "", cDateDoc := ""
Static cCntAnalit := "" ,cDocDim := ""
  Local cRet := "",i,n := 0,lSeek := .F.
  Local cDimId,cAlg := ""

  begin sequence
  if !(cCnt == (::mAliasInv)->CNT_TYPE) .Or. len(::aTabCnt) < 1
    cCnt := (::mAliasInv)->CNT_TYPE
    if !(cCnt $ {"1","2"})
      cVidDoc := ""
      cNumDoc := ""
      cDateDoc := ""
      cCntAnalit := ""
      cCntDocId := ""
    else

      n := 0
      for i := 1 to len(::aTabCnt)
        if cCnt == ::aTabCnt[i][1]
          n := i
          exit
        endif
      next
      if n == 0
        ::CreateBrg(cCnt)
        n := len(::aTabCnt)
      endif
    endif
    cCntDocId := (::mAliasInv)->CNT_DOC_ID
    lSeek := .T.
  elseif cCnt $ {"1","2"}
    if !(cCntDocId == (::mAliasInv)->CNT_DOC_ID )
      cCntDocId := (::mAliasInv)->CNT_DOC_ID
      for i := 1 to len(::aTabCnt)
        if cCnt == ::aTabCnt[i][1]
          n := i
          exit
        endif
      next
      lSeek := .T.
    endif
  else
    Break
  endif

  if lSeek .And. (n > 0)
    if ::aTabCnt[n][2]:Seek(cCntDocId,.T.,::aTabCnt[n][3])
      if cCnt == "1"
        cVidDoc := ::aTabCnt[n][2]:FieldValue("VID")
        cNumDoc := ::aTabCnt[n][2]:FieldValue("NUMDOC_E")
        cDateDoc := DTOC(::aTabCnt[n][2]:FieldValue("DATE"))
        cDimId := "0000000000000000001044"
        cDocDim :=  ::aTabCnt[n][2]:FieldValue("DOCDIM")
      else
        cVidDoc := "Заказ"//::aTabCnt[n][2]:FieldValue("dopcode")
        cNumDoc := ::aTabCnt[n][2]:FieldValue("numdoc")
        cDateDoc := DTOC(::aTabCnt[n][2]:FieldValue("date"))
        if (::mAliasInv)->TI_CTG == "1"
          cDimId := "0000000000000000001059" // Заказ покупка
        else
          cDimId := "0000000000000000001008"
        endif
        cDocDim :=  ::aTabCnt[n][2]:FieldValue("DOCDIM")
      endif
      if (DIC_Dim_anl)->(DbSeek(cDimId))
        cAlg := AllTrim((DIC_Dim_anl)->ALG_CODE)
        cCntAnalit := (::aTabCnt[n][2]:Alias)->(&cAlg)
      endif
    else
      cVidDoc := ""
      cNumDoc := ""
      cDateDoc := ""
      cCntAnalit := ""
      cCntDocId := ""
      cDocDim := ""
      Break
    endif
    /*
    if nParam == 4 .And. cCnt $ {"1","2"}
      if (DIC_Dim_anl)->(DbSeek(cDimId))
        cAlg := AllTrim((DIC_Dim_anl)->ALG_CODE)
        cCntAnalit := (::aTabCnt[n][2]:Alias)->(&cAlg)
      endif
    endif
    */
  endif

  if nParam == 1 // вид д-та
    cRet := cVidDoc
  elseif  nParam == 2 // номер д-та
    cRet := cNumDoc
  elseif nParam == 3  // дата д-та
    cRet := cDateDoc
  elseif nParam == 4  // аналитика д-та
    cRet := cCntAnalit
  elseif nParam == 5  // доп.измерение д-та
    cRet := cDocDim
  endif

  end sequence
Return cRet

Method clsTax_Inv:ChengeSumStatus(lAll)
Local nRec := ::DS:RecNo()
Local nRecMark := ::MarkFirst()
Local nLock := 0,nAll:= 0,nSum:= 0,cMsg := ""
  if nRecMark == 0
    if lAll
      if (::mAliasInv)->(DbRLock())
          (::mAliasInv)->IS_FULL := .T.
          (::mAliasInv)->(DbRUnLock())
      endif
    else
      if (::mAliasInv)->SUM_A <> (::mAliasInv)->SUM_BOOK
        if (::mAliasInv)->(DbRLock())
          (::mAliasInv)->IS_FULL := .F.
          (::mAliasInv)->(DbRUnLock())
        endif
      else
        messagebox("Изменение невозможно - запись сформирована на полную сумму",TITLEAPP,48)
      endif
    endif
    Return .T.
  endif
  do while !(nRecMark == 0 )
    nAll += 1
    (::mAliasInv)->(DbGoTo(nRecMark))
    if lAll
      if (::mAliasInv)->(DbRLock())
          (::mAliasInv)->IS_FULL := .T.
          (::mAliasInv)->(DbRUnLock())
      else
        nLock += 1
      endif
    else
      if (::mAliasInv)->SUM_A <> (::mAliasInv)->SUM_BOOK
        if (::mAliasInv)->(DbRLock())
          (::mAliasInv)->IS_FULL := .F.
          (::mAliasInv)->(DbRUnLock())
        else
          nLock += 1
        endif
      else
        nSum += 1
      endif
    endif
    nRecMark := ::MarkNext()
  enddo
  if nLock > 0 .Or. nSum > 0
    cMsg := "Статус изменен в " + Alltrim(Str(nAll-nLock-nSum)) + " счетах-фактурах" + chr(13) + chr(10)
    if nSum > 0
      cMsg += "Изменение невозможно в " + Alltrim(Str(nSum)) + " счетах-фактурах - " + chr(13) + chr(10)
      cMsg += "записи сформированы на полную сумму." + chr(13) + chr(10)
    endif
    if nLock > 0
      cMsg += "Изменение не произведено в " + Alltrim(Str(nLock)) + " счетах-фактурах - " + chr(13) + chr(10)
      cMsg += "записи заблокированы другими пользователями." + chr(13) + chr(10)
    endif
    messagebox(cMsg,TITLEAPP,48)
  endif
  ::DS:MarkAll(.F.)
Return .T.

Method clsTax_Inv:SetParamStrSum()
Local oStr,oSum,cAl,cAlTaxTp,cAlSprNds
local lStorno := ((::mAliasInv)->MOVE_TP $ {'СЗ','СП'})
Local cModId := (::mAliasInv)->MOD_ID//,s := "",n := 0,cTag,cTagSpr
  // ???? Проверить на соответствие существующую и налоговую одель документа
  if Empty(cModId)
    cModId := ::mParamIni[4]
  endif
  oStr := ::TAX_STR
  oStr:mDate := (::mAliasInv)->DOC_DATE
  oStr:mStorno := lStorno
  oStr:mTiCtg := (::mAliasInv)->TI_CTG
  oStr:mIdMod := cModId
  oSum := ::TAX_STR:TAXSTRSUM
  oSum:maModStr := {}
  oSum:mDate := (::mAliasInv)->DOC_DATE
  oSum:mStr_Tp :=(::mAliasStr)->Str_Tp
  oSum:mTiCtg := (::mAliasInv)->TI_CTG
  oSum:mStorno := lStorno

  oStr:SetEvent("ChangedStr",self,"CreateTaxForSF")
  //oSum:SetEvent("TaxSumRefreshForCls",self,"CreateTaxForSTR")
  cAl := oSum:mMODSTR
  cAlTaxTp :=  oSum:mTAX_TP
  cAlSprNds := oSum:mTbSprNds

  if !CreateArModStr(@oSum:maModStr,cAl,cAlTaxTp,cAlSprNds,cModId)
    Return .F.
  endif
  /*
  cTag := (cAl)->(OrdSetFocus("TAG_PRIOR"))
  cTagSpr := (cAlSprNds)->(OrdSetFocus("TAG_OPER"))
  (cAl)->(OrdScope(0,cModId))
  (cAl)->(OrdScope(1,cModId))
  (cAl)->(DbGoTop())
  if (cAl)->(Eof())
     messagebox("Не определены строки налоговой модели!")
     Return .F.
  endif
  do while !(cAl)->(Eof())
    if (cAlTaxTp)->(DbSeek((cAl)->TAX_ID))
      s := (cAlTaxTp)->SYS_NUM
    endif
    if (cAlSprNds)->(DbSeek((cAl)->RT_DEF))
      n := (cAlSprNds)->NDS
    endif
    AADD(oSum:maModStr, {(cAl)->TAX_ID,;
                         (cAl)->CALC_RL,;
                         (cAl)->MOD_BS,;
                         (cAl)->STR_ID,;
                         (cAl)->RT_DEF,;
                         n,;
                         s,;
                         (cAl)->PRIOR;
                           })
    (cAl)->(DbSkip(1))
  enddo
  (cAl)->(OrdSetFocus(cTag))
  (cAlSprNds)->(OrdSetFocus(cTagSpr))
  */
  oStr := nil
  oSum := nil
Return .T.

Method clsTax_Inv:Pereschet()
  local oErr
  Local nRec := ::TAX_STR:RecNo()
  Local lPer,lAllPer := .F.
  begin sequence
  (::mAliasStr)->(DbGoTop())
  Do while !(::mAliasStr)->(Eof())
    lPer := .F.
    if (::mAliasStr)->IS_HANDN .Or. (::mAliasStr)->IS_HANDA
      lPer := .T.
    else
      ::TAX_STR:TAXSTRSUM:GoTop()
      do while !(::mAliasSum)->(Eof())
        if (::mAliasSum)->IS_HAND
          // 28296 pg если изменяли акциз без ставки - пересчет не делаем
          //if !(Alltrim(::TAX_STR:TAXSTRSUM:SYS_NUM) == "1" .And. Empty((::mAliasSum)->TAX_IDRT))
            lPer := .T.
            Exit
          //endif
        endif
        (::mAliasSum)->(DbSkip(1))
      enddo
      ::TAX_STR:TAXSTRSUM:GoTop()
    endif
    if lPer
      ::TAX_STR:ChangedSum(,.T.)
      lAllPer := .T.
    endif
    (::mAliasStr)->(DbSkip(1))
  enddo
  (::mAliasStr)->(DbGoTo(nRec))
  if lAllPer
    ::CreateTaxForSF()
  endif
  recover using oErr
    if valtype(oErr) == "L"
      return oErr
    else
      return .F.
    endif
  end sequence
Return .T.

Method clsTax_Inv:GetDocForStr(cDocName)
  local oErr ,cIdStr,cType,cJrn
  Local i,n,cNum,cVid,cDate,nTab,cKey,cMsg
  Local a := {}
  //Материалы, Товары, Услуги
  begin sequence

  cIdStr := ::TAX_STR:STR_ID
  cDocName := ""
  if !::TAX_STR:STR_SRC
    Break .T.
  endif
  cType := ::TAX_STR:STR_TP
  do case
    case  cType == "2"
      cJrn := "0301"
      cNum := "numdoc"
      cVid  := "codedoc"
      cDate := "date"
      cKey  := "NNOPER_"
      cMsg := "Товары "

    case  cType == "3"
      cJrn := "0901"
      cNum := "numdoc"
      cVid  := "codedoc"
      cDate := "date"
      cKey  := "NNOPER_"
      cMsg := "Материалы "
    case  cType == "4"
      if ::TI_CTG == "1"
        cJrn := "TV01"
      else
        cJrn := "0501"
      endif
      cNum := "tek_nomer"
      cVid  := "type_p"
      cDate := "tek_data"
      cKey  := "NNOPER_"
      cMsg := "Услуги "
     otherwise
      Break(.T.)
  endcase
  if ::TI_CTG == "1"
    cMsg += " оприходованы."
  else
    cMsg += " отгруженны."
  endif
  for nTab := 1 to len(::aTab)
    if cJrn == ::aTab[nTab][5]
      exit
    endif
  next
  for i := 1 to len(::aSFDOC)
    if Len(a) < 1 .And. ::aSFDOC[i][_SFSTRID] == cIdStr .And. !::aSFDOC[i][_DEL]
      for n := 1 to len(::maTbDoc)
        if Len(a) < 1 .And. cJrn == ::maTbDoc[n][1]
          // Запись может быть новая
          // или взятая на редактирование
          if ::aSFDOC[i][_STATUS] != "0"
          // у строки документа в поле Oper_Fact
          // может не быть записи или запись не соответствует
          // строке - перевыбрали тот же документ
            (::maTbDoc[n][5])->(OrdSetFocus(::aTab[nTab][8]))
            if Len(a) < 1 .And. (::maTbDoc[n][5])->(DbSeek(::aSFDOC[i][_DOCSTRID]))
              (::maTbDoc[n][2])->(OrdSetFocus(::aTab[nTab][2]))
              if (::maTbDoc[n][2])->(DbSeek((::maTbDoc[n][5])->&cKey))
                AADD(a,(::maTbDoc[n][2])->&cVid + " № " + (::maTbDoc[n][2])->&cNum + " от " + DTOC((::maTbDoc[n][2])->&cDate) )
              endif
            endif
          else
            (::maTbDoc[n][5])->(OrdSetFocus(::aTab[nTab][7]))
            if Len(a) < 1 .And. (::maTbDoc[n][5])->(DbSeek(cIdStr))
              (::maTbDoc[n][2])->(OrdSetFocus(::aTab[nTab][2]))
              do while (::maTbDoc[n][5])->Oper_Fact == cIdStr
                if (::maTbDoc[n][2])->(DbSeek((::maTbDoc[n][5])->&cKey))
                /*
                cNum := (::maTbDoc[n][2])->&cNum
                cVid := (::maTbDoc[n][2])->&cVid
                cDate := DTOC((::maTbDoc[n][2])->&cDate)
                */
                  if !Empty((::maTbDoc[n][2])->Oper_Fact)
                    AADD(a,(::maTbDoc[n][2])->&cVid + " № " + (::maTbDoc[n][2])->&cNum + " от " + DTOC((::maTbDoc[n][2])->&cDate) )
                  endif
                endif
                (::maTbDoc[n][5])->(DbSkip(1))
              enddo
            endif
          endif
        endif
      next
    endif
  next
  if Len(a) < 1
    ::TAX_STR:Qnty_Shp := 0
    ::TAX_STR:STR_SRC := .F.
    Break(.T.)
  endif
  cMsg += chr(13) + chr(10)
  cMsg += "Документ: " + chr(13) + chr(10)
  //+ cVid + " № " + cNum + " от " + cDate
  for i := 1 to len(a)
    cMsg += a[i]  + chr(13) + chr(10)
  next
  cDocName := cMsg
  recover using oErr
    if valtype(oErr) == "L"
      return oErr
    else
      return .F.
    endif
  end sequence
Return .T.

Method clsTax_Inv:GetPartnerEval(nIdPartner,cExp,cValue)
local  oErr
 begin sequence
 if (::mAliasInv)->PRT_TP == "1"
   if (DIC_PARTNER)->(DbSeek(nIdPartner,.T.,"TAG_ID"))
     cValue := (DIC_PARTNER)->(&(cExp))
   else
     Break(.F.)
   endif
 else
   if (::mTbPeople)->(DbSeek(nIdPartner,.T.,"TAG_IDP"))
     cValue := (::mTbPeople)->(&(cExp))
   else
     Break(.F.)
   endif
 endif
 recover using oErr
   if valtype(oErr) == "L"
     return oErr
   else
     return .F.
  endif
 end sequence
Return .T.

Method clsTax_Inv:ReplaceNdsFromKalk(aNdsAll)
Local cIdRateN,lNoNds
  if !(aNdsAll[2] == nil) // ставка определена
    if aNdsAll[2] == 0
      lNoNds := aNdsAll[5]
    endif
    cIdRateN := ""
    if !((::mAliasSum)->TAX_RATE == aNdsAll[2]) .Or. (aNdsAll[2] == 0)
      if !CheckIdRateForRate(,aNdsAll[2],@cIdRateN,,"2",lNoNds)
        messagebox(" Не удалось получить идентификатор ставки для НДС!",TITLEAPP,48)
        Return .F.
      endif
      (::mAliasSum)->TAX_IDRT := cIdRateN
    endif
    (::mAliasSum)->TAX_RATE := aNdsAll[2]
  else
    (::mAliasSum)->TAX_IDRT := ""
  endif
  //(::mAliasSum)->TAX_RATE := aNdsAll[2]
  (::mAliasSum)->TAX_BASE := aNdsAll[4]
  (::mAliasSum)->TAX_SUM  := aNdsAll[3]
  (::mAliasStr)->SUM_NDS := aNdsAll[3]
  (::mAliasStr)->SUM_NNDS := aNdsAll[4] - aNdsAll[3]
  (::mAliasStr)->SUM_A := aNdsAll[4]
Return .T.

METHOD SFKVID()
Local s := "", cKey
Local cAl
  if (::mAliasInv)->DEF
    cKey := (::mAliasInv)->SFD_ID
  else
    cKey := (::mAliasInv)->SFK_ID
  endif
  if !Empty(cKey)
    if (::cWa)->FROM_ARC
      ::SeekFromArc(cKey,"MOVE_TP",@s)
    else
      cAl := ::mTbInv
      (cAl)->(OrdSetFocus("TAG_ID"))
      if (cAl)->(DbSeek(cKey))
        s := (cAl)->MOVE_TP
      endif
    endif

  endif
Return s

METHOD SFKNUM()
Local s := "", cKey
Local cAl
  if (::mAliasInv)->DEF
    cKey := (::mAliasInv)->SFD_ID
  else
    cKey := (::mAliasInv)->SFK_ID
  endif
  if !Empty(cKey)
    if (::cWa)->FROM_ARC
      ::SeekFromArc(cKey,"DOC_NUM",@s)
    else
      cAl := ::mTbInv
      (cAl)->(OrdSetFocus("TAG_ID"))
      if (cAl)->(DbSeek(cKey))
        s := (cAl)->DOC_NUM
      endif
    endif

  endif
Return s

METHOD SFKDOPNUM()
Local s := "", cKey
Local cAl
  if (::mAliasInv)->DEF
    cKey := (::mAliasInv)->SFD_ID
  else
    cKey := (::mAliasInv)->SFK_ID
  endif
  if !Empty(cKey)
    if (::cWa)->FROM_ARC
      ::SeekFromArc(cKey,"DNUM",@s)
    else
      cAl := ::mTbInv
      (cAl)->(OrdSetFocus("TAG_ID"))
      if (cAl)->(DbSeek(cKey))
        s := (cAl)->DNUM
      endif
    endif

  endif
Return s

METHOD SFKDATE()
Local s := "", cKey
Local cAl
  if (::mAliasInv)->DEF
    cKey := (::mAliasInv)->SFD_ID
  else
    cKey := (::mAliasInv)->SFK_ID
  endif
  if !Empty(cKey)
    if (::cWa)->FROM_ARC
      ::SeekFromArc(cKey,"DOC_DATE",@s)
    else
      cAl := ::mTbInv
      (cAl)->(OrdSetFocus("TAG_ID"))
      if (cAl)->(DbSeek(cKey))
        s := (cAl)->DOC_DATE
      endif
    endif

  endif
Return s

Method clsTax_Inv:OBLNUM()
  local  s := "" //a,
  //begin sequence
  if (::mAliasInv)->CNT_TYPE == "1" .And. !Empty((::mAliasInv)->CNT_DOC_ID) .And. !Empty((::mAliasInv)->ID_OBL)
    s := GetNumObl((::mAliasInv)->ID_OBL)
  endif
  /*
  if (::mAliasInv)->CNT_TYPE == "1" .And. !Empty((::mAliasInv)->CNT_DOC_ID) .And. !Empty((::mAliasInv)->ID_OBL)
    if !(ValType(::mTbCard) == "O")
      ::mTbCard := CreateDbRecord(B6_DBF_PATH + "AP\ap_card.dbf", "TAG_OSN")
    endif
  else
    Break(nil)
  endif
  a := SetWorkAreaCurrentState(::mTbCard:alias, {"TAG_DOC",,,,0})
  if (::mTbCard:alias)->(DbSeek((::mAliasInv)->ID_OBL))
    s := Str((::mTbCard:alias)->lnum,3,0)
  endif
  SetWorkAreaCurrentState(::mTbCard:alias, a)
  */
  //end sequence
Return s

Method clsTax_Inv:CheckObl()
Local n := 0,i
Local cCnt := (::mAliasInv)->CNT_TYPE
  if !(cCnt == "1")
    Return .T.
  endif
  if Empty((::mAliasInv)->CNT_DOC_ID)
    Return .T.
  endif
  if !Empty((::mAliasInv)->ID_OBL)
    Return .T.
  endif
  for i := 1 to len(::aTabCnt)
    if cCnt == ::aTabCnt[i][1]
      n := i
      exit
    endif
  next
  if n == 0
    ::CreateBrg(cCnt)
     n := len(::aTabCnt)
  endif

  if n > 0 .And. ::aTabCnt[n][2]:Seek((::mAliasInv)->CNT_DOC_ID,.T.,::aTabCnt[n][3])
    if ::aTabCnt[n][2]:FieldValue("is_phase")
      Return .F.
    endif
  endif
Return .T.
/*
//определяем как заполняется партионная карточка
Method clsTax_Inv:GetPAdd(cArm)
Local cPath, s

   if cArm == '03'
     cPath:= B6_DBF_PATH+'SCLAD\'
   elseif cArm == '09'
     cPath:= B6_DBF_PATH+'ZAPAS\'
   else
     return .t.
   endif

   s  := GetParamsIsTbUserFieldXVal(cPath + "user.dbf", {{'',"MAIN","nGenPAdd"}})[1]
   if cArm == '03'
     ::cGenPAddSclad := s
   elseif cArm == '09'
     ::cGenPAddZapas := s
   endif
Return .T.
*/
// nFor - 0 - старый банк
//        1 - старая касса
//        2 - новые денежные средства
Method clsTax_Inv:CreateForDoc51OrderRbook(tb,nFor,aLoc)
  local oErr
  Local cTbName,cTbNameM,cRBook := "" ,cRBookM := ""
  Local StrTp := "",cKey := ""
  Local cAlLb := "",cAlGr := ""
  Local cAlSLb := "", cAlZLb := "",cAlTLb := ""
  Local cAlSGr := "",cAlZGr := "",cAlTGr := ""
  Local cIdRateN,cIdRateA,lRet,nNds,nAcz,nBaseNds,nBaseAcz,nBaseForAcz //nSum,
  Local aSelectDoc := {},n,m,k,nJrn,lAdd,i
  Local cItemTp,lTov,aModStr := {},nSumA,nSumNNds,mTax
  Local cDop := ""
  Local cKOPNDS := Space(2),cKOPNNDS := Space(7),cKOPNDS0 := Space(7),cKOPAGNDS := Space(7)
  Local cKeyDoc ,lR , cKeyCard
  local cBrgType, cBrgId
  begin sequence
  ::DelAllStr()

  (tb)->(DbGoTo(aLoc[1]))
  if ::TI_CTG == "1"
    cTbName := "TOVAR\RBOOK.Dbf"
    cTbNameM := "TOVAR\RBOOKM.Dbf"
    lTov := .T.
  else
    cTbName := "REAL\RBOOK.Dbf"
    cTbNameM := "REAL\RBOOKM.Dbf"
    //cItemTp := "2" //"Т"
    lTov := .F.
  endif
  if ! _DbAreaOpen(B6_DBF_PATH + cTbName, @cRBook,"TAG_OPER")
     break(.F.)
  endif
  if ! _DbAreaOpen(B6_DBF_PATH + cTbNameM, @cRBookM,"Tag_Oper_")
     break(.F.)
  endif
  if nFor $ {0,1}
    if !(cRBook)->(DbSeek((tb)->CNT_DOC_ID))
      Break(.F.)
    endif
    cBrgType := (tb)->CNT_TYPE
    cBrgId := (tb)->CNT_DOC_ID

  elseif nFor == 2
  // В деньгах - идентификатор карточки
    cKeyDoc := ""
    lR  := .F.
    cKeyCard := (tb)->ACNT_ID
    if LookUpSeek("Ap\AP_Card.Dbf","TAG_ID",@lR,cKeyCard,"DOC_ID",@cKeyDoc)
      if lR
        if !(cRBook)->(DbSeek(cKeyDoc))
          Break(.F.)
        endif
        cBrgType := (tb)->BRG_TP
        cBrgId := cKeyDoc
      else
        Break(.F.)
      endif
    else
      Break(.F.)
    endif
  else
    Break(.F.)
  endif

  (cRBookM)->(OrdScope(0,(cRBook)->NNOPER))
  (cRBookM)->(OrdScope(1,(cRBook)->NNOPER))
  (cRBookM)->(DbGoTop())
  Do While !(cRBookM)->(Eof())
    /*
      2 - товары если ITEM_TP=T
      3 - материалы если ITEM_TP=M
      4 - услуги если ITEM_TP=У
    */
    if lTov
      cItemTp := (cRBookM)->ITEM_TP
    else
      if (cRBook)->STATUS $ {"6","7"}
        cItemTp := "4"
      else
        cItemTp := "2"
      endif
    endif
    do case
      case cItemTp == "2" //"Т"
        StrTp := "2"
        if Select(cAlSlb) < 1
          if ! _DbAreaOpen(B6_DBF_PATH + "Sclad\MLabel.dbf", @cAlSLb,"MLABEL")
            break(.F.)
          endif
          if ! _DbAreaOpen(B6_DBF_PATH + "Sclad\MGrup.dbf", @cAlSGr,"MGrup")
            break(.F.)
          endif
        endif
        cAllb := cAlSlb
        cAlGr := cAlSGr
      case cItemTp == "3" //"М"
        StrTp := "3"
        if Select(cAlZlb) < 1
          if ! _DbAreaOpen(B6_DBF_PATH + "Zapas\MLabel.dbf", @cAlZLb,"MLABEL")
            break(.F.)
          endif
          if ! _DbAreaOpen(B6_DBF_PATH + "Zapas\MGrup.dbf", @cAlZGr,"MGrup")
            break(.F.)
          endif
        endif
        cAllb := cAlZlb
        cAlGr := cAlZGr
      case cItemTp == "4" //"У"
        StrTp := "4"
        if Select(cAlTlb) < 1
          if ! _DbAreaOpen(B6_DBF_PATH + "Tovar\MLabel.dbf", @cAlTLb,"MLABEL")
            break(.F.)
          endif
          if ! _DbAreaOpen(B6_DBF_PATH + "Tovar\MGrup.dbf", @cAlTGr,"MGrup")
            break(.F.)
          endif
        endif
        cAllb := cAlTlb
        cAlGr := cAlTGr
    endcase

    if!::TAX_STR:BeforAppend(StrTp,.T.) //kostia ошибка 31170 передадим SrtTp  !::TAX_STR:BeforAppend("0",.T.)
      messagebox("Не удалось создать строку счета-фактуры!",TITLEAPP,48)
      Break(.F.)
    endif
    if !::TAX_STR:Append()
      messagebox("Не удалось создать строку счета-фактуры!",TITLEAPP,48)
      Break(.F.)
    endif
    (::mAliasStr)->STR_TP := StrTp
    (::mAliasStr)->STR_SRC := .T.
    (::mAliasStr)->GROUP_CODE := (cRBookM)->GRUP
    (::mAliasStr)->NNUM := (cRBookM)->NNUM
    cKey := Upper((cRBookM)->GRUP + (cRBookM)->NNUM)
    if (cAlLb)->(DbSeek(cKey))
      (::mAliasStr)->NNAME := (cAlLb)->NAME
    else
      (::mAliasStr)->NNAME := " "
    endif
    (::mAliasStr)->MDIM := (cRBookM)->MDIM

    (::mAliasStr)->SUM_NDS := (cRBookM)->SUM_NDS
    // 35057
    //Если RBOOK.LNDS=F, TAX_BASE=RBOOKM.SUMOUT+ TAX_SUM для НДС
    //Если RBOOK.LNDS=T, TAX_BASE=RBOOKM.SUMOUT
    //для акциза тоже елис не входит, то прибавить, елис входит, то взять как есть
    // pg  - получается что nBaseNds - это всегда сумма с налогом
    if (cRBook)->L_NDS
      //nBaseNds := (cRBookM)->SUMOUT - (cRBookM)->SUM_NDS
      nBaseNds := (cRBookM)->SUMOUT
      nBaseForAcz := (cRBookM)->SUMOUT - (cRBookM)->SUM_NDS
    else
      //nBaseNds := (cRBookM)->SUMOUT
      nBaseNds := (cRBookM)->SUMOUT + (cRBookM)->SUM_NDS
      nBaseForAcz := (cRBookM)->SUMOUT
    endif
    if (cRBook)->L_ACZ
      //nBaseAcz := nBaseNds - (cRBookM)->SUM_ACZ
      nBaseAcz := nBaseForAcz
    else
      //nBaseAcz := nBaseNds
      nBaseAcz := nBaseForAcz + (cRBookM)->SUM_ACZ
    endif
    aModStr := ::TAX_STR:TAXSTRSUM:maModStr
    nSumA := (cRBookM)->SUMOUT
    nSumNNds := (cRBookM)->SUMOUT
    for i :=  1 to len(aModStr)
      if AllTrim(aModStr[i][_SYSNUM]) == "1"
      //Акциз
        mTax := (cRBookM)->SUM_ACZ
      else
        mTax := (cRBookM)->SUM_NDS
      endif
      if (cRBook)->L_NDS
        if !aModStr[i][_PRICEIN]
          nSumNNds := nSumNNds - mTax
        endif
      else
        nSumA := nSumA + mTax
        if aModStr[i][_PRICEIN]
          nSumNNds := nSumNNds + mTax
        endif
      endif
    next

   (::mAliasStr)->SUM_A := nSumA
   (::mAliasStr)->SUM_NNDS := nSumNNds
     /*
    if (cRBook)->L_NDS .AND. (cRBook)->L_ACZ
      (::mAliasStr)->SUM_A := (cRBookM)->SUMOUT
    else
      nSum := (cRBookM)->SUMOUT
      if !(cRBook)->L_NDS
        nSum := nSum + (cRBookM)->SUM_NDS
      endif
      if !(cRBook)->L_ACZ
        nSum := nSum + (cRBookM)->SUM_ACZ
      endif
      (::mAliasStr)->SUM_A := nSum
    endif

    (::mAliasStr)->SUM_NNDS := (::mAliasStr)->SUM_A - (::mAliasStr)->SUM_NDS
    */
    // Налоги
    // Получим налоги из группы
    cKey := Upper((cRBookM)->GRUP)
    if !(cAlGr)->(DbSeek(cKey))
      Break(.F.)
    endif
    // НДС
    // 34735
    //заказа продажи
    //\REAL\RBOOKM ставка налога по строке (TAX_RATE, TAX_IDRT)формируется так:
    //Запись таблицы SPR_ NDS со ставкой ищется на основе полей
    //RBOOKM.NDS(ставка) и RBOOKM.NONDS(без НДС) из строки заказа


    if lTov
      nNds := (cAlGr)->NDS
      if !(cItemTp == "4")
        nAcz := (cAlGr)->PA
      endif
      cIdRateN := (cAlGr)->oper_nds
      // Проверим соответствие идентификатора - ставке
      if !Empty(cIdRateN)
        lRet := .F.
        if !LookUpSeek("SPR_NDS","TAG_OPER",@lRet,cIdRateN)
          Break(.F.)
        endif
        if !lRet
           cIdRateN := ""
        endif
      endif
      if Empty(cIdRateN)
        if !CheckIdRateForRate(,(cAlGr)->NDS,@cIdRateN,,"2")
          messagebox(" Не удалось получить идентификатор ставки для НДС!",TITLEAPP,48)
          Break(.F.)
        endif
      endif
    else
      nNds := (cRBookM)->NDS
      if !CheckIdRateForRate(,nNds,@cIdRateN,,"2",(cRBookM)->NONDS)
        messagebox(" Не удалось получить идентификатор ставки для НДС!",TITLEAPP,48)
        Break(.F.)
      endif
    endif
    if Empty(cIdRateN)
       messagebox(" Не удалось получить идентификатор ставки для НДС!",TITLEAPP,48)
       Break(.F.)
    endif

 //////////////////////////////////
    // Получаем идентификатор ставки для акциза
    cIdRateA := ""
    if !(cItemTp == "4")
      if !Empty((cRBookM)->SUM_ACZ)
      // Получаем идентификатор Акциза
        nAcz := (cAlGr)->PA
        if !CheckIdRateForRate(,(cAlGr)->PA,@cIdRateA,,"1")
          messagebox(" Не удалось получить идентификатор ставки для Акциза!",TITLEAPP,48)
          Break(.F.)
        endif
      else
        nAcz := 0
      endif
    endif
    ::TAX_STR:TAXSTRSUM:MoveFirst()
    do while !(::mAliasSum)->(EOF())
      do case
        case Alltrim(::TAX_STR:TAXSTRSUM:SYS_NUM) == "1"
          if !(cItemTp == "4")
            (::mAliasSum)->TAX_RATE := nAcz
            (::mAliasSum)->TAX_IDRT := cIdRateA
            (::mAliasSum)->TAX_SUM := (cRBookM)->SUM_ACZ
            (::mAliasSum)->TAX_BASE := nBaseAcz
            (::mAliasSum)->IS_HAND := .F.
          endif
        case Alltrim(::TAX_STR:TAXSTRSUM:SYS_NUM) == "2"
          (::mAliasSum)->TAX_RATE := nNds
          (::mAliasSum)->TAX_IDRT := cIdRateN
          (::mAliasSum)->TAX_SUM := (cRBookM)->SUM_NDS
          (::mAliasSum)->TAX_BASE := nBaseNds
          (::mAliasSum)->IS_HAND := .F.
      endcase

      (::mAliasSum)->(DbSkip(1))
     enddo

    (cRBookM)->(DbSkip(1))
  enddo

  // Перенесем документ основания

  if Empty((::mAliasInv)->CNT_DOC_ID)
     (::mAliasInv)->CNT_TYPE := cBrgType
     if !(cBrgType == "3")
       (::mAliasInv)->CNT_DOC_ID := cBrgId
       (::mAliasInv)->ID_OBL := (tb)->ID_OBL
     endif
  endif

  if Empty((::mAliasInv)->ACNT_ID) // счет нужно брать из документа
    if nFor == 0
      (::mAliasInv)->ACNT_ID := (tb)->cr
      (::mAliasInv)->ANALIT := (tb)->Scr
    elseif nFor == 1
      (::mAliasInv)->ACNT_ID := (tb)->kschet
      (::mAliasInv)->ANALIT := (tb)->An_KSchet
    endif
  endif

  if Empty(cKOPNDS)
    cKOPNDS :=  (tb)->KOP_NDS
  endif
  if Empty(cKOPNNDS)
    cKOPNNDS :=  (tb)->KOP_NNDS
  endif
  if Empty(cKOPNDS0)
    cKOPNDS0 :=  (tb)->KOP_NDS0
  endif
  if Empty(cKOPAGNDS)
    cKOPAGNDS :=  (tb)->KOP_AG_NDS
  endif

  if !Empty(cKOPNDS)
    (::mAliasInv)->KOP_NDS := cKOPNDS
  endif
  if !Empty(cKOPNNDS)
    (::mAliasInv)->KOP_NNDS := cKOPNNDS
  endif
  if !Empty(cKOPNDS0)
    (::mAliasInv)->KOP_NDS0 := cKOPNDS0
  endif
  if !Empty(cKOPAGNDS)
    (::mAliasInv)->KOP_AG_NDS := cKOPAGNDS
  endif

  if nFor == 0
    AADD(aSelectDoc,{(tb)->NNOPER_ID,(tb)->(RecNo())})
    nJrn := "0101"
    cDop := (tb)->NAME
  elseif nFor == 1
    AADD(aSelectDoc,{(tb)->NNOPER,(tb)->(RecNo())})
    nJrn := "0201"
    cDop := (tb)->REASON
  elseif nFor == 2
    AADD(aSelectDoc,{(tb)->RowId,(tb)->(RecNo())})
    if (tb)->FIN_CTG == "1"
      nJrn := "PM01"
    else
      nJrn := "PM02"
    endif
    cDop := (tb)->COMMENT
  endif
  if !Empty(cDop)
    ::DS:FieldValue("COMPL_m",cDop)
  endif

  n := len(::aSfDoc)
  m := len(aSelectDoc)
  if n > 0 .And. nJrn ==  ::aSfDoc[1][_JRNID]
      lAdd := .T.

      for k := 1 to n
        for i := 1 to m
          if ::aSfDoc[k][_DOCID] == aSelectDoc[i][1]
             ::aSfDoc[k][_SFSTRID] := ::TAX_STR:STR_ID
             ::aSfDoc[k][_STATUS] := 0
             ::aSfDoc[k][_DEL] := .F.
             lAdd := .F.
          endif
        next
      next
      if lAdd
       if nFor == 0
         cKey := nJrn+(tb)->NNOPER_ID+"1"
       else
         cKey := nJrn+(tb)->NNOPER+"1"
       endif
       AADD(::aSfDoc,{(::mAliasInv)->DOC_ID,;
                       ::TAX_STR:STR_ID,;
                       aSelectDoc[i][1] ,;
                       aSelectDoc[i][1] ,;
                       nJrn,;
                       .F.,;
                       1,cKey,aSelectDoc[i][2]})
      endif

 else
   n := len(aSelectDoc)
   for i := 1 to n
     if nFor == 0
       cKey := nJrn+(tb)->NNOPER_ID+"1"
     elseif nFor == 1
       cKey := nJrn+(tb)->NNOPER+"1"
     elseif nFor == 2
       cKey := nJrn+(tb)->RowId+"1"
     endif
     AADD(::aSfDoc,{(::mAliasInv)->DOC_ID,;
                     ::TAX_STR:STR_ID,;
                     aSelectDoc[i][1] ,;
                     aSelectDoc[i][1] ,;
                     nJrn,;
                     .F.,;
                     1,cKey,aSelectDoc[i][2]})
   next
 endif

  Break(.T.)
  recover using oErr
    _DbAreaClose(cRBook)
    _DbAreaClose(cRBookM)
    _DbAreaClose(cAlSLb)
    _DbAreaClose(cAlZLb)
    _DbAreaClose(cAlTLb)
    _DbAreaClose(cAlSGr)
    _DbAreaClose(cAlZGr)
    _DbAreaClose(cAlTGr)

    if valtype(oErr) == "L"
      return oErr
    else
      return .F.
    endif
  end sequence
Return .T.
// проверим нужно ли делать авансовый с-ф по заказу
// nFor - 0 - старый банк
//        1 - старая касса
//        2 - новые денежные средства
Method clsTax_Inv:CheckRBook(tb,nFor,aLoc,nRet)
  local oErr ,nTaxBase,nSumAll,cTbName,cRBook := ""
  Local cKey,dDocDate,cBrgType ,cBrgId, cKeyCard, lR
  begin sequence
  nRet := 1
  (tb)->(DbGoTo(aLoc[1]))
  if nFor == 2
    cBrgType := (tb)->BRG_TP
  else
    cBrgType := (tb)->CNT_TYPE
  endif
  if len(aLoc) == 1 .And. cBrgType == "2"
    if nFor == 2
      nTaxBase := (tb)->SUM
      nSumAll := (tb)->SUM
    else
      nTaxBase := (tb)->SUMMA
      nSumAll := (tb)->SUMMA
    endif
    if nFor == 0
      cKey := (tb)->NNOPER_ID
      dDocDate := (tb)->DOPER
    elseif nFor == 1
      cKey := (tb)->NNOPER
      dDocDate := (tb)->DATAOPER
    elseif nFor == 2
      cKey := (tb)->ROWID
      dDocDate := (tb)->OPER_DATE
    endif
    if !SumForAvans(@nTaxBase,cKey,dDocDate)
      Break(.F.)
    endif
   // Для одного документа  34520 - доработка - аванс на заказ
    if  nTaxBase == nSumAll
    // Аванс на полную сумму платежного документа
       if ::TI_CTG == "1"
         cTbName := "TOVAR\RBOOK.Dbf"
       else
         cTbName := "REAL\RBOOK.Dbf"
       endif
       if ! _DbAreaOpen(B6_DBF_PATH + cTbName, @cRBook,"TAG_OPER")
          break(.F.)
       endif

       if nFor $ {0,1}
         cBrgId := (tb)->CNT_DOC_ID
       elseif nFor == 2
       // В деньгах - идентификатор карточки
         cBrgId := ""
         lR  := .F.
         cKeyCard := (tb)->ACNT_ID
         if LookUpSeek("Ap\AP_Card.Dbf","TAG_ID",@lR,cKeyCard,"DOC_ID",@cBrgId)
           if !lR
             Break(.F.)
           endif
         else
           Break(.F.)
         endif
       else
         Break(.F.)
       endif


       if (cRBook)->(DbSeek(cBrgId))
         if (cRBook)->SUMTOTAL == nSumAll
             nRet := upgCustomMsg("Полная оплата заказа." + chr(13) + chr(10) + "Формировать позиции счета-фактуры",,;
                                 {"По всему заказу  ",;
                                  "По каждой позиции"},,.T.,.T.)


         endif
       endif
     endif
  endif
  break(.T.)
  recover using oErr
    _DbAreaClose(cRBook)
    if valtype(oErr) == "L"
      return oErr
    else
      return .F.
    endif
  end sequence
Return .T.
// Проверяем создан ли с-ф по заказу
Method clsTax_Inv:IsRBook(lZac)
Local lRet := .T.,nRecNo := (::mAliasStr)->(RecNo())
  begin sequence
  lZac  := .F.
  if (::cWa)->Move_Tp $ "ПР,ПП"
    nRecNo := (::mAliasStr)->(RecNo())
    (::mAliasStr)->(DbGoTop())
    Do While !(::mAliasStr)->(Eof())
      if (::mAliasStr)->STR_SRC
        if !((::mAliasStr)->STR_TP $ "0,1")
          lZac := .T.
          exit
        endif
      endif
      (::mAliasStr)->(dbSkip(1))
    enddo
   endif

  recover
    lRet := .F.
  end sequence

  (::mAliasStr)->(DbGoTo(nRecNo))
Return lRet
// проверяем налоги под платежный документ если создали по заказу
Method clsTax_Inv:CheckTaxForZac(nRet)
local oErr
Local lRet := .T. ,cOldTag,cKey
Local cTbName,cParamNDS,cParamSum,cAlsPrm := ""
Local tb ,aNds ,nRecNo ,r ,i ,lNds,lNoRate ,cKeyKalk
Local aModStr
  begin sequence
  // Определим для какого журнала смотреть калькуляцию
  nRet := 0
  nRecNo := (::mAliasSum)->(RecNo())
  cOldTag := (::mAliasSum)->(OrdName())
  if len(::maTbDoc) == 0
    Break(.T.)
  endif
  tb := ::maTbDoc[1][2]
  if ::maTbDoc[1][1] == "0101"
    cTbName := "Bank\kalk_d_b.dbf"
    cParamNDS := "NDS"
    cParamSum := "R1"
    cKeyKalk :=  (tb)->oper_kalk
  elseif ::maTbDoc[1][1] == "0201"
    cTbName := "Cash\kalk_d_k.dbf"
    cParamNDS := "NDS_18"
    cParamSum := "S_NDS18"
    cKeyKalk :=  (tb)->oper_kalk
  else
  // Для остальных журналов ни чего не делаем
    Break(.T.)
  endif

  if ! _DbAreaOpen(B6_DBF_PATH + cTbName, @cAlsPrm,"TAG_PAR")
    Break(.F.)
  endif

  // Определим налоги и суммы в калькуляции
  if !(cAlsPrm)->(DbSeek(cKeyKalk))
  // Нет калькуляции под документ
    Break(.T.)
  endif
  aNds := {}
  if (cAlsPrm)->(DbSeek(cKeyKalk + Padr(cParamNDS,10)))
    AADD(aNds,{18,(cAlsPrm)->znahen,,.F.,0})
    i := len(aNds)
    if (cAlsPrm)->(DbSeek(cKeyKalk + Padr(cParamSum,10)))
      aNds[i][3] := (cAlsPrm)->znahen
    endif
  endif
  if (cAlsPrm)->(DbSeek(cKeyKalk + Padr("NDS_10",10)))
    AADD(aNds,{10,(cAlsPrm)->znahen,,.F.,0})
    i := len(aNds)
    if (cAlsPrm)->(DbSeek(cKeyKalk + Padr("S_NDS10",10)))
      aNds[i][3] := (cAlsPrm)->znahen
    endif
  endif
  if (cAlsPrm)->(DbSeek(cKeyKalk + Padr("NDS_0",10)))
    AADD(aNds,{0,(cAlsPrm)->znahen,,.F.,0})
    i := len(aNds)
    if (cAlsPrm)->(DbSeek(cKeyKalk + Padr("S_NDS0",10)))
      aNds[i][3] := (cAlsPrm)->znahen
    endif
  endif
  if (cAlsPrm)->(DbSeek(cKeyKalk + Padr("NDS_N",10)))
    AADD(aNds,{0,(cAlsPrm)->znahen,,.T.,0})
    i := len(aNds)
    if (cAlsPrm)->(DbSeek(cKeyKalk + Padr("S_NDSN",10)))
      aNds[i][3] := (cAlsPrm)->znahen
    endif
  endif

  if len(aNds) < 1
    Break(.T.)
  endif
  aModStr :=  ::TAX_STR:TAXSTRSUM:maModStr
  if (len(aModStr) = 1 .And. AllTrim(aModStr[1][_SYSNUM]) == "1") .Or. len(aModStr) > 1
     r:= upgCustomMsg("       Налоги по авансовому счету-фактуре," + chr(13) + chr(10) + ;
                      "         сформированные на основе заказа,"+ chr(13) + chr(10) + ;
                      "не совпадают с налогами по платежному документу." ,,;
            {"Не сохранять",;
             "Продолжить"},,.T.,.T.)
    nRet := r
  endif
  cOldTag := (::mAliasSum)->(OrdSetFocus("TAG_TAX"))
  cKey := (::mAliasInv)->Doc_ID + (::mAliasInv)->Doc_ID
  (::mAliasSum)->(OrdScope(0,cKey))
  (::mAliasSum)->(OrdScope(1,cKey))
  (::mAliasSum)->(dbGoTop())
  do while !(::mAliasSum)->(Eof())
    lNoRate := .T.
    if (::mAliasSum)->TAX_RATE  == 0
     // Проверим 0 ставка или не облагается
      lRet := .F.
      lNds := .F.
      if !LookUpSeek("SPR_NDS","TAG_OPER",@lRet,(::mAliasSum)->TAX_IDRT,"NONDS",@lNds)
        Break(.F.)
      endif
      if !lRet
        Break(.F.)
      endif
    else
      lNds := .F.
    endif
    for i := 1 to len(aNds)
      if (::mAliasSum)->TAX_RATE == aNds[i][2] .And. lNds == aNds[i][4]
        if aNds[i][3]  ==  (::mAliasSum)->TAX_SUM
          aNds[i][5] := 1
          lNoRate := .F.
        endif
      endif
    next
    if lNoRate
      Exit
    endif
    (::mAliasSum)->(DbSkip(1))
  enddo
  if lNoRate
    lRet := .F.
  else
    lRet := .T.
    for i := 1 to len(aNds)
      if aNds[i][5] = 0
        lRet := .F.
        exit
      endif
    next
  endif
  if !lRet
     r:= upgCustomMsg("       Налоги по авансовому счету-фактуре," + chr(13) + chr(10) + ;
                      "         сформированные на основе заказа,"+ chr(13) + chr(10) + ;
                      "не совпадают с налогами по платежному документу." ,,;
            {"Сохранять",;
             "Не сохранять",;
             "Продолжить"},,.T.,.T.)
    if r == 1
      nRet := 0
    elseif r == 2
      nRet := 1
    elseif r == 3
      nRet := 2
    endif
  endif
  lRet := .T.
  recover  using oErr
    if valtype(oErr) == "L"
      lRet := oErr
    else
      lRet := .F.
    endif
  end sequence
  (::mAliasSum)->(OrdSetFocus(cOldTag))
  (::mAliasSum)->(DbGoTo(nRecNo))
  _DbAreaClose(cAlsPrm)
Return lRet

Method clsTax_Inv:CheckUniqueNum(lReg,sMess)
  Local cTag ,cKey
  local lUnique := .F.
  begin sequence
  if ValType(lReg) != "L"
    lReg := .F.
  endif
  sMess := ""
  if lReg
    cTag := "TAG_NUMREG"
    cKey := (::mAliasInv)->DOC_TP + left(DTOS((::mAliasInv)->REG_DATE),4) + Upper((::mAliasInv)->REG_NUM)
  else
    if (::mAliasInv)->DEF
      cTag := "TAG_SFD"
      cKey := (::mAliasInv)->SFD_ID + Upper((::mAliasInv)->DOC_NUM)
    else
      cTag := "TAG_NUM"
      cKey := (::mAliasInv)->DOC_TP + left(DTOS((::mAliasInv)->DOC_DATE),4) + Upper((::mAliasInv)->DOC_NUM)
    endif

  endif
  if Empty(::mTbInv)
    if ! _DbAreaOpen(B6_DBF_PATH + "Tax\Tax_Inv.dbf", @::mTbInv,cTag)
      Break (nil)
    endif
  endif
  (::mTbInv)->(OrdSetFocus(cTag))

  if lReg
    // Проверить уникальность в пределах вида и года
    lUnique := .T.
    if (::mTbInv)->(DbSeek(cKey,.T.,"TAG_NUMREG"))
      do while (::mTbInv)->DOC_TP + left(DTOS((::mTbInv)->DOC_DATE),4) + Upper((::mTbInv)->REG_NUM) == cKey
          //Такой же номер но не на этой записи
         if (::mTbInv)->(RecNo()) != (::mAliasInv)->(RecNo())
           lUnique := .F.
           Exit
         endif
         (::mTbInv)->(DbSkip(1))
      enddo
    endif
    if !lUnique
      sMess := "Регистрационный номер счета-фактуры не уникален!"
    endif
  else
    if (::mAliasInv)->DEF
      lUnique := .T.
      if (::mTbInv)->(DbSeek(cKey,.T.,cTag))
        do while  cKey == (::mTbInv)->SFD_ID + Upper((::mTbInv)->DOC_NUM)
          if (::mTbInv)->(RecNo()) != (::mAliasInv)->(RecNo())
            lUnique := .F.
            Exit
          endif
          (::mTbInv)->(DbSkip(1))
        enddo
      endif
    elseif (::mAliasInv)->TI_CTG == "1"
      // Проверяем в пределах вида, контрагента и года
      lUnique := .T.
      if ::mParamIni[_TAX_IN_NUM]
        if (::mTbInv)->(DbSeek(cKey,.T.,cTag))
           do while (::mTbInv)->DOC_TP + left(DTOS((::mTbInv)->DOC_DATE),4) + Upper((::mTbInv)->DOC_NUM) == cKey
             //Для это го же партнера
             if (::mTbInv)->PRT_ID == (::mAliasInv)->PRT_ID
               //Такой же номер но не на этой записи
               if (::mTbInv)->(RecNo()) != (::mAliasInv)->(RecNo())
                 if (::mAliasInv)->MOVE_TP $ "ОТ,БП,ЗК"
                   if !((::mTbInv)->IS_COMB .And. (::mAliasInv)->IS_COMB)
                     lUnique := .F.
                     Exit
                   endif
                 else
                   lUnique := .F.
                   Exit
                 endif
               endif
             endif
             (::mTbInv)->(DbSkip(1))
           enddo
       //endif
        endif
      endif
    else
     //  Проверяем в пределах вида и года
      // Проверяем в пределах вида, контрагента и года
      lUnique := .T.
      if (::mTbInv)->(DbSeek(cKey,.T.,cTag))
        do while (::mTbInv)->DOC_TP + left(DTOS((::mTbInv)->DOC_DATE),4) + Upper((::mTbInv)->DOC_NUM) == cKey
           //Такой же номер но не на этой записи
          if (::mTbInv)->(RecNo()) != (::mAliasInv)->(RecNo())
            if (::mAliasInv)->MOVE_TP $ "ОТ,БП,ЗК"
              if !((::mTbInv)->IS_COMB .And. (::mAliasInv)->IS_COMB)
                lUnique := .F.
                Exit
              endif
            else
              lUnique := .F.
              Exit
            endif
          endif
          (::mTbInv)->(DbSkip(1))
        enddo
      endif
    endif
    if !lUnique
      if !(::mAliasInv)->DEF .And. (::mAliasInv)->MOVE_TP $ "ОТ,БП,ЗК"
        sMess := "Номер счета-фактуры не уникален!"
        sMess += ' Измените номер, или установите признак "Сводный"'
        sMess += ' для всех счетов-фактур с совпадающими номерами.'
      else
        sMess := "Номер счета-фактуры не уникален!"
      endif
    endif
  endif

  recover
    lUnique  :=  .F.
    sMess := "Ошибка проверки уникальности номера!"
  end sequence
Return lUnique

Method clsTax_Inv:lNegativPozit()
local aNegativ := {.F.,.F.,0,0}
local nRec := ::TAX_STR:RecNo()
  (::mAliasStr)->(DbGoTop())
  Do While !(::mAliasStr)->(Eof())
    if ((::mAliasStr)->STR_V == "P") .And. ( (::mAliasStr)->SUM_A < 0)
      aNegativ[2] := .T.
      aNegativ[4] += (::mAliasStr)->SUM_A
    elseif ((::mAliasStr)->STR_V == "P") .And. ( (::mAliasStr)->SUM_A >= 0 )
      aNegativ[1] := .T.
      aNegativ[3] += (::mAliasStr)->SUM_A
    endif
    (::mAliasStr)->(DbSkip(1))
  enddo
  aNegativ[4] := abs(aNegativ[4])
 (::mAliasStr)->(DbGoTo(nRec))
Return aNegativ

Method clsTax_Inv:CreateArrStrAssets(cAlStr,cCard,lGroup,aRec,dDoc, IdNds, nRecNo)
  local oErr,aRecOneDoc := {},aSort := {},nPr, cPr ,nQ , nNds
  local nPrStr,i,cKey := "",j := 0 ,lRet
  local cIdNDS := "" ,RetValue, Key,k
  local cAlSprNds := ""
  local cMsg := ""
  local rNds := 0 , rAllNds := 18
  local IdStrNds := "", cAlAssGr := ""
  begin sequence
  lRet := .F.
  Key := "НДС"
  RetValue := ""
  if !LookUpSeek("TAX\TAX_TP","TAG_CODE",@lRet,Key,"TAX_ID",@RetValue)
    Break(.F.)
  endif
  if !lRet
    Break(.F.)
  endif
  if ! _DbAreaOpen(B6_DBF_PATH + "SPR_NDS.DBF", @cAlSprNds,"TAG_IDNDS")
    Break(.F.)
  endif
  if ! _DbAreaOpen(B6_DBF_PATH + "ASSETS\RES_GR.DBF", @cAlAssGr,"TAG_CD")
    Break(.F.)
  endif
  Key := RetValue + str(18,19,5)
  (cAlSprNds)->(OrdScope(0,Key))
  (cAlSprNds)->(OrdScope(1,Key))
  (cAlSprNds)->(DbGoTop())
  if (cAlSprNds)->(eof())
    //messagebox("Нет ставки НДС 18%.",TITLEAPP,48)
    //break(.F.)
    cMsg := "Нет ставки НДС 18%."
  else
    Do While !(cAlSprNds)->(Eof())
      if dDoc >= (cAlSprNds)->DATE_BEG
        if Empty((cAlSprNds)->DATE_END)
          IdNds := (cAlSprNds)->NNOPER
          exit
        else
          if  dDoc <= (cAlSprNds)->DATE_END
            IdNds := (cAlSprNds)->NNOPER
            exit
          endif
        endif
      endif
      (cAlSprNds)->(DbSkip(1))
    enddo
  endif
  (cAlSprNds)->(OrdScope(0,nil))
  (cAlSprNds)->(OrdScope(1,nil))
  (cAlSprNds)->(OrdSetFocus("TAG_OPER"))
  if Empty(IdNds)
    //messagebox("Нет действующей на дату документа ставки НДС 18%.",TITLEAPP,48)
    //break(.F.)
    cMsg := "Нет действующей на дату документа ставки НДС 18%."
  endif

  Do While !(cAlStr)->(Eof())
    if (cAlStr)->ISMBOOK
      if !(cCard)->(DbSeek( (cAlStr)->CARD_ID ))
        Break(.F.)
      endif
      IdStrNds := ""
      rNds := rAllNds
      if (cAlStr)->QNTY > 0
        nQ := (cAlStr)->QNTY
      else
        nQ := 1
      endif
      if !(cAlAssGr)->(DbSeek( Upper((cCard)->group )))
        Break(.F.)
      else
        IdStrNds := (cAlAssGr)->TAX_ID
        if !Empty(IdStrNds)
          if (cAlSprNds)->(DbSeek(IdStrNds))
            rNds := (cAlSprNds)->NDS
          endif
        else
          Key := (cAlAssGr)->ID_PARENT
          if Key > 1
            (cAlAssGr)->(OrdSetFocus("TAG_ID"))
            do while .T.
              if (cAlAssGr)->(DbSeek( Key ))
                Key := (cAlAssGr)->ID_PARENT
                IdStrNds := (cAlAssGr)->TAX_ID
                if !Empty(IdStrNds)
                   if (cAlSprNds)->(DbSeek(IdStrNds))
                     rNds := (cAlSprNds)->NDS
                   endif
                   exit
                endif
                if Key = 1
                  exit
                endif
              else
                exit
              endif
            enddo
          endif
        endif
      endif
      if Empty(IdStrNds)
        if !Empty(cMsg)
          messagebox(cMsg,TITLEAPP,48)
          break(.F.)
        endif
        rNds := rAllNds
        IdStrNds := IdNds
      endif
      nPr := (cAlStr)->PRICE_SL
      //nNds := Round(nPr * 18/118,4)
      nNds := Round(nPr * rNds/(100 + rNds),4)
      nPrStr :=( nPr -  nNds) / nQ
      nPrStr := Round(nPrStr,4)
      cPr := Str(nPrStr,19,4)

      AADD(aRecOneDoc,{(cCard)->GROUP + (cCard)->NNUM + (cCard)->UNIT + cPr + IdStrNds ,;
                       (cCard)->GROUP ,;
                       (cCard)->NNUM ,;
                       (cCard)->UNIT,;
                       nPr,;
                       nQ,;
                       nNds,;
                       (cCard)->NAME,;
                       {{nRecNo,(cAlStr)->(RecNo()),(cAlStr)->STR_ID}},;
                       rNds,;
                       IdStrNds;
                       })
    endif
    (cAlStr)->(DbSkip(1))
  enddo
  //aRecOneDoc := ASort(aRecOneDoc,,,{|aX,aY|aX[1] < aY[1]})
  if lGroup
    for i := 1 to len(aRec)
      AADD(aSort,aRec[i])
    next
    aRec := {}
    for i := 1 to len(aRecOneDoc)
      AADD(aSort,aRecOneDoc[i])
    next
    aSort := ASort(aSort,,,{|aX,aY|aX[1] < aY[1]})
    cKey := ""
    j := 0
    for i := 1 to len(aSort)
      if !(cKey == aSort[i][1])
        cKey := aSort[i][1]
        AADD(aRec,aSort[i])
        j ++
      else
        aRec[j][5] += aSort[i][5]
        aRec[j][6] += aSort[i][6]
        for k := 1 to len(aSort[i][9])
          AADD(aRec[j][9],aSort[i][9][k])
        next
      endif
    next
  else
    for i := 1 to len(aRecOneDoc)
      AADD(aRec,aRecOneDoc[i])
    next
  endif
  Break(.T.)
  recover using oErr
    _DbAreaClose(cAlSprNds)
    _DbAreaClose(cAlAssGr)
    if valtype(oErr) == "L"
      return oErr
    else
      return .F.
    endif
  end sequence
Return .T.

Method clsTax_Inv:DelAllRec()
  local oBook,nRec,a := {} ,i,oObjBook
  begin sequence
  oBook := ::BOOK:DS
  nRec := oBook:RecNo()
  oBook:GoTop()
  Do while !oBook:Eof()
    if !(oBook:CMP_TP $ "1,3")
      AADD(a,{oBook:RecNo(),oBook:BOOK_ID})
    endif
    oBook:Skip(1)
  enddo
  oBook:GoTo(nRec)
  oBook := ::BOOKST:DS
  nRec := oBook:RecNo()
  oBook:GoTop()
  Do while !oBook:Eof()
    if !(oBook:CMP_TP $ "1,3")
      AADD(a,{oBook:RecNo(),oBook:BOOK_ID})
    endif
    oBook:Skip(1)
  enddo
  oObjBook := clsTax_Book():New()
  if (::cWa)->MOVE_TP $ {'ПР','ПП'}
    oObjBook:lSfStDel := .F.
  else
    oObjBook:lSfDel := .F.
  endif
  oObjBook:Open()
  oObjBook:lDelDocs := .F.
  for i := 1 to len(a)
    oObjBook:GoTo(a[i][1])
    oObjBook:Delete()
  next
  end sequence
  if ValType(oObjBook) == "O"
    oObjBook:Destroy()
    oObjBook := nil
  endif
Return .T.

Method clsTax_Inv:GetTaxInvFrom()
  if Empty(::mTbInvArc) .Or. Select(::mTbInvArc) < 1
    if ! _DbAreaOpen(B6_DBF_PATH + "Tax\Arc\TAX_INV.dbf", @::mTbInvArc,"TAG_ID")
      RETURN .F.
    endif
  endif
Return ::mTbInvArc

Method clsTax_Inv:SeekFromArc(cKey,cField,value)
local cAl := ::GetTaxInvFrom()

  (cAl)->(OrdSetFocus("TAG_ID"))
  if !(cAl)->(DbSeek(cKey))
    cAl := ::mTbInv
    (cAl)->(OrdSetFocus("TAG_ID"))
    if !(cAl)->(DbSeek(cKey))
      Return .T.
    endif
  endif
  value := (cAl)->&cField
Return .T.


//Для построения темпового индекса при отборе сторнирующий
// с-ф в книге
Method clsTax_Inv:SelectKorrSf()
local aKorr := ::lNegativPozit()
local n
  if aKorr[1] .And. !Empty(::mDateSf)
    n := select()
    if !(::cWa)->IS_ANUL .And. ((::cWa)->REG_DATE >= ::mDateSf )
      if ChechRegKorrForSt(self) > 0
         select(n)
         Return  .T.
      endif
      n := select()
    endif
  endif
Return .F.

Method clsTax_Inv:CreateRecInBookWithoutDoc(lStartForm)
local oObjBook, aParam
begin sequence
  if ValType(lStartForm) != "L"
    lStartForm := .F.
  endif
  oObjBook := clsTax_Book():New()
  oObjBook:Open()
  if (::mAliasInv)->TI_CTG == "1"
    aParam := {0,"1","ОП"}
  else
    aParam := {0,"2","ОТ"}
  endif
  if !oObjBook:BeforeAppend(aParam)
    Break(.F.)
  endif
  if !oObjBook:Append()
    Break(.F.)
  endif
  oObjBook:SF_ID := (::cWA)->DOC_ID
  oObjBook:SRC_DATE := (::cWA)->DOC_DATE
  oObjBook:SRC_SUM :=  oObjBook:SF_RST
  if lStartForm
    if !StartFrmBook(oObjBook)
       Break(nil)
    endif
  elseif !oObjBook:save()
    if !StartFrmBook(oObjBook)
       Break(nil)
    endif
  endif

 end sequence
 if ValType(oObjBook) == "O"
    oObjBook:Destroy()
  endif
  oObjBook := Nil
Return .T.
/*
Function SelectKorrSf()
local s := ""
Return.T.
*/
/*
Method clsTax_Inv:AsKorr(IdSfKorr)
local lRet := (::cWa)->KORR
  IdSfKorr := (::cWa)->SFK_ID
  if !lRet .And. (::cWa)->DEF .And. !Empty((::cWa)->SFD_ID)
    (::mTbInv)->(OrdSetFocus("TAG_ID"))
    if (::mTbInv)->(DbSeek((::cWa)->SFD_ID))
      lRet := (::mTbInv)->KORR
      IdSfKorr := (::mTbInv)->SFK_ID
    endif
  endif
return lRet
*/
/*
Function
  local oErr
  begin sequence

  recover using oErr
    if valtype(oErr) == "L"
      return oErr
    else
      return .F.
    endif
  end sequence
Return .T.
*/