// celso GAY E muito
/*------------------------------------------------------------------------
    File        : Faturamento.p
    Purpose     :

    Syntax      :

    Description :
            
    Author(s)   :
    Created     : Wed Dec 06 09:17:00 BRST 2017
    Notes       :
  ----------------------------------------------------------------------*/
/* ***************************  Definitions  ************************** */
routine-level on error undo, throw.
/*------------------------------------------------------------------------
    File        : simular-faturamento.i 
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Thu Oct 05 15:55:56 BRT 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
define temp-table temp-faturamento-contrato no-undo
    field in-modalidade                     as   integer
    field in-termo                          as   integer
    field in-ano                            as   integer
    field in-mes                            as   integer
    field dc-valor-total                    as   decimal.
    
    
define temp-table temp-faturamento-beneficiario   
                                            no-undo    
    field in-modalidade                     as   integer
    field in-termo                          as   integer
    field in-usuario                        as   integer
    field in-ano                            as   integer
    field in-mes                            as   integer
    field in-evento                         as   integer
    field ch-classe-evento                  as   character
    field dc-valor                          as   decimal
    field ch-tipo-movimento                 as   character.
    

/*------------------------------------------------------------------------
    File        : utilidades.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Fri Oct 06 09:35:13 BRT 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */

/* ************************  Function Prototypes ********************** */


function BuscaValorFaturamentoPrepagamentoContrato returns decimal 
    (in-modalidade      as   integer,
     in-termo           as   integer,
     in-ano             as   integer,
     in-mes             as   integer) FORWARD.

function EhEventoMensalidade returns logical 
    (ch-classe-evento               as   character ) FORWARD.

function IdadeBeneficiario returns integer 
    (dt-nascimento      as   date,
     dt-calculo         as   date  ) FORWARD.

function ValorTotalMensalidade returns decimal 
    (in-modalidade          as   integer,
     in-termo               as   integer,
     in-usuario             as   integer) forward.

/* ***************************  Main Block  *************************** */


/* ************************  Function Implementations ***************** */

function BuscaValorFaturamentoPrepagamentoContrato returns decimal 
    (in-modalidade      as   integer,
     in-termo           as   integer,
     in-ano             as   integer,
     in-mes             as   integer):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    
    define variable dc-valor                    as   decimal    no-undo.
    
    define buffer buf-notaserv                  for  notaserv.
    
    find first buf-notaserv no-lock
     use-index notaserv7    
         where buf-notaserv.cd-modalidade       = in-modalidade
           and buf-notaserv.nr-ter-adesao       = in-termo
           and buf-notaserv.aa-referencia       = in-ano
           and buf-notaserv.mm-referencia       = in-mes
           and (   buf-notaserv.in-tipo-nota    = 0
                or buf-notaserv.in-tipo-nota    = 5)
               no-error.
              
    if available buf-notaserv
    then assign dc-valor    = buf-notaserv.vl-total.

    return dc-valor.
        
end function.

function EhEventoMensalidade returns logical 
    (ch-classe-evento               as   character ):

    if ch-classe-evento    = "A"
    or ch-classe-evento    = "K"
    or ch-classe-evento    = "L"
    or ch-classe-evento    = "N"
    or ch-classe-evento    = "O"
    or ch-classe-evento    = "P"
    or ch-classe-evento    = "Q"
    or ch-classe-evento    = "W"
    or ch-classe-evento    = "4"
    then do:
        return yes.
    end.                                     
    return no.       
end function.

function IdadeBeneficiario returns integer 
    (dt-nascimento      as   date,
     dt-calculo         as   date  ):

    define variable lg-erro                                     as   logical    no-undo.
    define variable in-idade-beneficiario                       as   integer    no-undo.
    
    run rtp/rtidade.p (input  dt-nascimento,
                       input  dt-calculo,
                       output in-idade-beneficiario,
                       output lg-erro).
                     
    if lg-erro then return ?.
    
    return in-idade-beneficiario.                         
        
end function.

function ValorTotalMensalidade returns decimal 
    (in-modalidade          as   integer,
     in-termo               as   integer,
     in-usuario             as   integer):
             
    define buffer buf-benef         for  temp-faturamento-beneficiario.    
    define variable dc-valor        as   decimal    no-undo.
    
    for each buf-benef
       where buf-benef.in-modalidade    = in-modalidade
         and buf-benef.in-termo         = in-termo
         and buf-benef.in-usuario       = in-usuario:
              
             
        find first evenfatu no-lock
             where evenfatu.in-entidade     = 'FT'
               and evenfatu.cd-evento       = buf-benef.in-evento.
             
        if EhEventoMensalidade (buf-benef.ch-classe-evento)
        then do:
            if buf-benef.ch-tipo-movimento  = 'CREDITO'
            then do:
                assign dc-valor = dc-valor + buf-benef.dc-valor.
            end.
            else do:
                assign dc-valor = dc-valor - buf-benef.dc-valor.
            end.   
        end.        
    end.
    return dc-valor.
end function.

procedure BuscaValorUltimoFaturamento:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define input  parameter in-modalidade       as   integer    no-undo.
    define input  parameter in-termo            as   integer    no-undo.
    define output parameter dc-valor            as   decimal    no-undo.
    
    define buffer buf-notaserv                  for  notaserv.
    
    find last buf-notaserv no-lock
        where buf-notaserv.cd-modalidade        = in-modalidade
          and buf-notaserv.nr-ter-adesao        = in-termo
          and buf-notaserv.aa-referencia       <> 0
          and buf-notaserv.mm-referencia       <> 0
          and (   buf-notaserv.in-tipo-nota     = 0
               or buf-notaserv.in-tipo-nota     = 5)
              no-error.
              
    if available buf-notaserv
    then assign dc-valor    = buf-notaserv.vl-total.
end procedure.
    
  

/*------------------------------------------------------------------------
    File        : data-vencimento.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Tue Dec 19 09:05:33 BRST 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */

/* ************************  Function Prototypes ********************** */


function CalculaDataVencimentoProposta returns datetime 
    (in-modalidade              as   integer,
     in-termo-adesao            as   integer,
     dt-emissao                 as   date,
     in-mes-referencia          as   integer,
     in-ano-referencia          as   integer) forward.


/* ***************************  Main Block  *************************** */

/* ************************  Function Implementations ***************** */


function CalculaDataVencimentoProposta returns datetime 
    (in-modalidade              as   integer,
     in-termo-adesao            as   integer,
     dt-emissao                 as   date,
     in-mes-referencia          as   integer,
     in-ano-referencia          as   integer):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define buffer buf-prop                  for  propost.
    define variable ep-codigo-aux           like propost.ep-codigo.
    define variable cod-estabel-aux         like propost.cod-estabel.
    define variable cd-tipo-vencimento-aux  like propost.cd-tipo-vencimento.
    define variable dd-vencimento-aux       like propost.dd-vencimento.
    define variable dt-vencimento-aux       as   date.
    define variable ds-mens-aux             as   character.
    define variable lg-erro-aux             as   logical.
    
    find first buf-prop no-lock
         where buf-prop.cd-modalidade   = in-modalidade
           and buf-prop.nr-ter-adesao   = in-termo-adesao.
           
     assign ep-codigo-aux            = propost.ep-codigo
            cod-estabel-aux          = propost.cod-estabel
            cd-tipo-vencimento-aux   = propost.cd-tipo-vencimento
            dd-vencimento-aux        = propost.dd-vencimento.    

    run rtp/rtdtvenc.p (input ep-codigo-aux,
                        input cod-estabel-aux,
                        input dd-vencimento-aux,
                        input dt-emissao,
                        input-output dt-vencimento-aux,
                        input in-mes-referencia,
                        input in-ano-referencia,
                        input cd-tipo-vencimento-aux,
                        output lg-erro-aux,
                        output ds-mens-aux).
    if (lg-erro-aux)     
    then do:
        return ?.        
    end.
    return dt-vencimento-aux.
        
end function.



 

/*------------------------------------------------------------------------
    File        : dates.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Tue Oct 13 14:54:32 BRT 2015
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */
define variable DATA_FORMATO_YYYY_MM_DD_COM_SEPARADOR   as   character          no-undo initial "YYYY-MM-DD".
define variable DATA_FORMATO_DD_MM_YYYY_COM_SEPARADOR   as   character          no-undo initial "DD-MM-YYYY".
define variable DATA_FORMATO_DD_MM_YYYY_SEM_SEPARADOR   as   character          no-undo initial "DDMMYYYY".

/* ********************  Preprocessor Definitions  ******************** */

/* ************************  Function Prototypes ********************** */

function FormatarData returns character
      (input ch-value           as date,
       input ch-format          as character, 
       input ch-separator       as character, 
       input lg-include-time    as logical,
       input ch-time-separator  as character) FORWARD.

function UltimoDiaMesAtual returns date 
        (  ) forward.

function DataEstaSobreposta returns logical
    (input dt-1-initial         as date,
     input dt-1-final           as date,
     input dt-2-initial         as date,
     input dt-2-final           as date) FORWARD.

function ConverterParaData returns date
    (input ch-date-string       as   character,
     input ch-formato           as   character) FORWARD.

function UltimoDiaMes returns date    
    (in-ano         as   integer,
     in-mes         as   integer) FORWARD.

function DiasNoMes returns integer 
        (in-ano as integer,
         in-mes as integer) forward.

function PrimeiroDiaMesAtual returns date 
        (  ) forward.


/* ***************************  Main Block  *************************** */




/* ************************  Function Implementations ***************** */
function DataEstaSobreposta returns logical
    (input dt-1-initial         as date,
     input dt-1-final           as date,
     input dt-2-initial         as date,
     input dt-2-final           as date):

    if (    dt-2-initial   >= dt-1-initial
        and dt-2-initial   <= dt-1-final)
    or (    dt-2-final     >= dt-1-initial
        and dt-2-final     <= dt-1-final)
    or (    dt-1-initial   >= dt-2-initial
        and dt-1-initial   <= dt-2-final)
    or (    dt-1-final     >= dt-2-initial
        and dt-1-final     <= dt-2-final)
    then return yes.
    else return no.
end function.



function ConverterParaData returns date
    (input ch-date-string       as   character,
     input ch-formato           as   character):

    define variable dt-value    as   date       no-undo.

    case ch-formato:
        when DATA_FORMATO_DD_MM_YYYY_SEM_SEPARADOR
        then do:
            dt-value    = date (integer (substring (ch-date-string, 3, 2)),
                                integer (substring (ch-date-string, 1, 2)),
                                integer (substring (ch-date-string, 5, 4)))
                                no-error.
            if error-status:error then return ?.                                
        end.
        when DATA_FORMATO_YYYY_MM_DD_COM_SEPARADOR
        then do:
            dt-value    = date (integer (substring (ch-date-string, 6, 2)),
                                integer (substring (ch-date-string, 9, 2)),
                                integer (substring (ch-date-string, 1, 4)))
                                no-error.
                             
            if error-status:error then return ?.                                        
        end.
        when DATA_FORMATO_DD_MM_YYYY_COM_SEPARADOR
        then do:
            dt-value    = ConverterParaData (replace (replace (ch-date-string, "/", ""), "-", ""), DATA_FORMATO_DD_MM_YYYY_SEM_SEPARADOR).
            if error-status:error then return ?.
        end.
        
        otherwise do:
        end.
    end.
    return dt-value.                                
         
end.     


function UltimoDiaMes returns date    
    (in-ano         as   integer,
     in-mes         as   integer):

    define variable dt-ultimo-dia-mes       as   date       no-undo.
         
    assign dt-ultimo-dia-mes    = date (in-mes, 1, in-ano)
           dt-ultimo-dia-mes    = add-interval (dt-ultimo-dia-mes, 1, "month")
           dt-ultimo-dia-mes    = dt-ultimo-dia-mes - 1.
           
    return dt-ultimo-dia-mes.           
         
end function.         

function DiasNoMes returns integer 
        (in-ano as integer,
         in-mes as integer):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/        

    define variable dt-ini      as   date   no-undo.
    define variable dt-fim      as   date   no-undo.
    
    assign dt-ini   = date (in-mes, 1, in-ano)
           dt-fim   = UltimoDiaMes (in-ano, in-mes).
           
    return interval (dt-fim, dt-ini, "days") + 1.           
end function.

function PrimeiroDiaMesAtual returns date 
        (  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/        
    return date (month (today), 1, year (today)).


                
end function.
             


function FormatarData returns character
      (input ch-value           as date,
       input ch-format          as character, 
       input ch-separator       as character, 
       input lg-include-time    as logical,
       input ch-time-separator  as character): 
       
    define variable va-format                 as character.
    define variable ch-original-date-format   as character format "x(3)". 
    define variable va-return                 as character.

    ch-original-date-format = session:date-format.

    case ch-format:
        when "YYYYMMDD" 
        then do:
            session:date-format = "YMD".
            va-format = "9999" + "-" + "99" + "-" + "99".
        end.
        when "MMDDYYYY" 
        then do:
            session:date-format = "MDY".
            va-format = "99" + "-" + "99" + "-" + "9999".
        end.  
        when "DDMMYYYY" 
        then do:
            session:date-format = "DMY".
            va-format = "99" + "-" + "99" + "-" + "9999".
        end.
  
        when "YYMMDD" 
        then do:
            session:date-format = "YMD".
            va-format = "99" + "-" + "99" + "-" + "99".
        end.
  
        when "MMDDYY" 
        then do:
            session:date-format = "MDY".
            va-format = "99" + "-" + "99" + "-" + "99".
        end.
  
        when "DDMMYY" 
        then do:
            session:date-format = "DMY".
            va-format = "99" + "-" + "99" + "-" + "99".
        end.
     
        when "ISO" 
        then do:
            va-return = iso-date (ch-value).
            va-return = replace (va-return,"-",ch-separator).
            va-return = replace (replace (va-return,":",ch-time-separator),".",ch-time-separator).  /* 2009-02-27T10:51:47.261-05:00 */
        end.
 
        otherwise
            va-format = "99" + "-" + "99" + "-" + "99".
     
    end case.   
  
    if ch-format <> "ISO" 
    then do:
        if lg-include-time 
        then va-return = replace(replace(replace(string(ch-value,va-format + " HH:MM:SS.SSS"),":",ch-time-separator),".",ch-time-separator)," ",ch-time-separator).
        else va-return = string(ch-value, va-format).
        
        va-return = replace(va-return,"-",ch-separator).
   end.
  
  
    session:date-format = ch-original-date-format. 
    return va-return.

end function.   

function UltimoDiaMesAtual returns date 
        (  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/        
    return UltimoDiaMes(year(today), month(today)).

                
end function.
  
   
/*------------------------------------------------------------------------
    File        : ExecutaFonteProgress.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Fri Dec 15 13:37:24 BRST 2017
    Notes       : 
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

/*------------------------------------------------------------------------
    File        : erro.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Wed Apr 26 11:31:43 BRT 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */

/* ************************  Function Prototypes ********************** */


function DispararException returns logical 
        (ch-descricao-erro             as   character,
         in-codigo-erro                as   integer) forward.


/* ***************************  Main Block  *************************** */

/* ************************  Function Implementations ***************** */


function DispararException returns logical 
        (ch-descricao-erro             as   character,
         in-codigo-erro                as   integer):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/        
    log-manager:write-message (substitute ('&1', ch-descricao-erro ),'ERROR').    
    undo, throw new Progress.Lang.AppError(ch-descricao-erro, in-codigo-erro).
    
                
end function.

 

/*------------------------------------------------------------------------
    File        : files.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Tue Apr 26 14:51:46 BRT 2016
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

/*------------------------------------------------------------------------
    File        : files_inc.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Mon May 08 19:10:33 GMT-03:00 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
define temp-table temp-arquivo-diretorio    no-undo
    field ch-nome-arquivo                   as   character
    field ch-nome-arquivo-sem-extensao      as   character 
    field ch-extensao-arquivo               as   character
    field ch-caminho-completo-arquivo       as   character
    index idx1
          ch-nome-arquivo
    index idx2
          ch-nome-arquivo-sem-extensao.
 

/* ********************  Preprocessor Definitions  ******************** */

/* ************************  Function Prototypes ********************** */


function ArquivoExiste returns logical 
        (ch-caminho-arquivo        as   character  ) FORWARD.

function CriarDiretorio returns character 
        (ch-caminho            as   character) forward.

function GerarArquivoTemporario returns character 
        (ch-extensao           as   character) forward.

function GerarNomeArquivoTemporario returns character 
        (ch-extensao           as   character) forward.
        
function LeConteudoArquivo returns longchar 
    (input ch-path          as   character,
     input ch-source-encode as   character,
     input ch-target-encode as   character) FORWARD.

function ListarArquivosDiretorio returns logical 
        (ch-diretorio          as   character,
         ch-extensao           as   character) forward.

/* ***************************  Main Block  *************************** */


/* ************************  Function Implementations ***************** */

function ArquivoExiste returns logical 
        (ch-caminho-arquivo        as   character  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/        
    file-info:file-name = ch-caminho-arquivo.
    
    return file-info:full-pathname <> ?.
                
end function.

function CriarDiretorio returns character 
        (ch-caminho            as   character):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/        
    os-create-dir value (ch-caminho).
    
end function.

function GerarArquivoTemporario returns character 
        (ch-extensao           as   character):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/        
    define variable ch-nome-arquivo-unico   as   character  no-undo.
    
    assign ch-nome-arquivo-unico   = session:temp-directory
           ch-nome-arquivo-unico   = substitute ("&1/&2", ch-nome-arquivo-unico, GerarNomeArquivoTemporario(ch-extensao)).
    
    return ch-nome-arquivo-unico.    
end function.

function GerarNomeArquivoTemporario returns character 
        (ch-extensao           as   character):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/        
    define variable rw-unique-id            as   raw        no-undo.
    define variable ch-guid                 as   character  no-undo.

    assign rw-unique-id = generate-uuid
           ch-guid      = guid(rw-unique-id). 
    return replace (replace (ch-guid, "-", ""), ".", "") + "." + ch-extensao.           
end function.

function ListarArquivosDiretorio returns logical 
        (ch-diretorio          as   character,
         ch-extensao           as   character):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
----------------------------------------------- -------------------------------*/       
    define variable hd-programa             as   handle         no-undo.
    
    if not valid-handle (hd-programa) then run utils/files.p persistent set hd-programa.
        
    run ListarArquivosDiretorio in hd-programa (input ch-diretorio, input ch-extensao, input-output table temp-arquivo-diretorio).
    
end function.

function LeConteudoArquivo returns longchar 
    (input ch-path          as   character,
     input ch-source-encode as   character,
     input ch-target-encode as   character):

    define variable ch-content      as   longchar.
    define variable ch-line         as   character.
    
    if  ch-source-encode   <> ?
    and ch-target-encode   <> ?
    then do:
        input from value (ch-path) convert source ch-source-encode target ch-target-encode.
    end.
    else input from value (ch-path).
    
    repeat:
        import unformatted ch-line.
        if (ch-content  = "")
        then do:
            ch-content  = ch-line.
        end.
        else do:
            ch-content = ch-content + chr(13) + ch-line.
        end.
    end.
    input close.
    
    return ch-content.
end function.        

 

/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
define temp-table temp-parametro-entrada        no-undo
    field in-id-execucao                        as   integer
    field ch-nome-programa                      as   character
    field ch-modo                               as   character
    field ch-parametros                         as   character
    field in-qt-dias                            as   integer
    field ch-modo-envio-dados                   as   character
    field ch-caminho-gravacao-arquivos          as   character
    field dt-qt-dias                            as   datetime
    field lg-parametros-periodos                as   logical    init no.
    
define temp-table temp-parametro-periodo        no-undo
    field in-ano                                as   integer
    field in-mes                                as   integer
    index idx1
          as primary as unique
          in-ano
          in-mes.    
    
define temp-table XML_EXECUCAO no-undo
    namespace-uri "http://www.thealth.com.br/StepExecution.xsd" 
    field ID_EXECUCAO as integer 
    field INICIO as datetime-tz 
    field FIM as datetime-tz 
    field OCORREU_ERRO as logical .

define temp-table XML_ERRO no-undo
    namespace-uri "http://www.thealth.com.br/StepExecution.xsd" 
    field CODIGO as integer 
    field MENSAGEM as character 
    field XML_EXECUCAO_id as recid 
        xml-node-type "HIDDEN" .

define dataset XML_EXECUCAODset namespace-uri "http://www.thealth.com.br/StepExecution.xsd" 
    xml-node-type "HIDDEN" 
    for XML_EXECUCAO, XML_ERRO
    parent-id-relation RELATION1 for XML_EXECUCAO, XML_ERRO
        parent-id-field XML_EXECUCAO_id.



    
define temp-table temp-base-comunicacao         no-undo
    field ch-chave-sistema                      as   character  xml-node-name 'CHAVE_SISTEMA'.
    
define variable MODO_EXECUCAO_TOTAL             as   character  init 'TOTAL'    no-undo.
define variable MODO_EXECUCAO_PARCIAL           as   character  init 'PARCIAL'  no-undo.

define variable ENVIAR_DADOS_WEBSERVICE         as   character  init 'WEBSERVICE'   no-undo.
define variable ENVIAR_DADOS_ARQUIVO            as   character  init 'ARQUIVO'   no-undo.
    
define new global shared variable hd-web-service                  as   handle                     no-undo.
define new global shared variable hd-progress-service             as   handle                     no-undo.

// Tabela que armazena as requisiäes assincronas dos webservices. Tem por finalidade apenas nÆo destruir o handle da requisiÆo para que o resultado possa ser processado

define temp-table temp-request-handlers         no-undo
    field hd-request as handle .

function ChamaWebServiceRetorno returns character 
    (in-task-id                         as   integer,
     lo-xml                             as   longchar ) FORWARD.

function EnviarDados returns logical 
    (hd-dataset             as   handle  ) FORWARD.

function FinalizarTarefa returns character 
    (in-id-task                     as   integer  ) FORWARD.

/* ************************  Function Prototypes ********************** */

function ReportarError returns character 
    (in-task-id                         as   integer) forward.

function ConverteData returns date 
    (ch-valor           as   character  ) FORWARD.

function PreparaWebService returns character 
    (  ) forward.

function RegistroPrimary returns character 
    (input hd-temp-table    as handle) forward.
    
function ConverteTempParaXml returns longchar 
    (hd-table-handle           as   handle) forward.    

/* ***************************  Main Block  *************************** */

/* ************************  Function Implementations ***************** */


function ReportarError returns character 
    (in-task-id                         as   integer):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    
    define variable ch-resposta         as   character  init '' no-undo.
    define variable ch-nome-arquivo     as   character  init '' no-undo.
    define variable lg-xml              as   logical            no-undo.
    define variable lo-xml              as   longchar           no-undo.

    find first temp-parametro-entrada.
    
    if temp-parametro-entrada.ch-modo-envio-dados   = ENVIAR_DADOS_WEBSERVICE
    then do:
        PreparaWebService().
        
        assign lo-xml   = ConverteTempParaXml (dataset XML_EXECUCAODset:handle).
        
        run ReportarErroEtapa in hd-progress-service (input in-task-id, input lo-xml) no-error.
        if error-status:error
        then do:
            return substitute ('nao foi possivel realizar a chamada EnviarDadosTarefa: &1 - &2',
                               error-status:get-number (1),
                               error-status:get-message (1)).
    
        end.
    end.
    else do:
        
        assign ch-nome-arquivo  = substitute ('&1/&2', temp-parametro-entrada.ch-caminho-gravacao-arquivos, '.error').
        lg-xml = dataset XML_EXECUCAODset:write-xml('file', ch-nome-arquivo, false, 'ISO8859-1', ?, false, false) no-error.
        if not lg-xml
        or error-status:error
        then do:
            log-manager:write-message (substitute ('erro: ', error-status:get-message (1)),'ERROR').            
        end.
    end.
end function.

function ConverteData returns date 
    (ch-valor           as   character  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    

    define variable dt-convertida   as   date       no-undo.
    
    assign dt-convertida = date (integer (entry (2, ch-valor, '/')),
                                 integer (entry (3, ch-valor, '/')),
                                 integer (entry (1, ch-valor, '/'))) no-error.
                      
    if error-status:error
    then return ?.        
    
    return dt-convertida.
        
end function.

function PreparaWebService returns character 
    (  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    
    
    if not valid-handle (hd-web-service)
    then do:
        create server hd-web-service.
    end.
     
    if not hd-web-service:connected ()
    then do:
        hd-web-service:connect ("-WSDL 'http://localhost:7640/Progress?wsdl'") no-error.
        if error-status:error
        then do:
            return substitute ('nao foi possivel conectar ao webservice: &1 - &2',
                               error-status:get-number (1),
                               error-status:get-message (1)).
        end.
    end.
    
    if not valid-handle (hd-progress-service)
    then do:
        run Progress set hd-progress-service on hd-web-service no-error.
        if error-status:error
        then do:
            return substitute ('nao foi possivel criar o handle do Progress: &1 - &2',
                               error-status:get-number (1),
                               error-status:get-message (1)).
    
        end.        
    end.

        
end function.


function RegistroPrimary returns character 
    (input hd-temp-table    as handle):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    
        
    define variable ch-keys         as character    no-undo.
    define variable in-num-keys     as integer      no-undo.
    define variable in-index        as integer      no-undo.
    define variable ch-holder       as character    no-undo.
    define variable ch-valor        as character    no-undo.

    assign ch-keys = hd-temp-table:keys(1).    
    if ch-keys = "rowid" then return "".
        
    assign in-num-keys = num-entries (ch-keys, ",").
    do in-index = 1 to in-num-keys:
        assign ch-valor = hd-temp-table:buffer-field (entry (in-index, ch-keys, ",")):buffer-value no-error.
        if not error-status:error
        then do:
            if ch-holder <> '' then ch-holder = ch-holder + ':'.
            ch-holder = ch-holder + substitute ("&1", ch-valor).
        end.        
    end.    
    return ch-holder.
        
end function.              

function ChamaWebServiceRetorno returns character 
    (in-task-id                         as   integer,
     lo-xml                             as   longchar ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    

    
end function.



/* **********************  Internal Procedures  *********************** */
procedure HandleProcedureReturn:    
    define input parameter dt-e             as   datetime       no-undo.
        
    log-manager:write-message(substitute ('hora do termino da requisiÆo: &1', dt-e)).
    process events.   
end procedure.



function EnviarDados returns logical 
    (hd-dataset             as   handle  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    
    define variable lo-xml                  as   longchar           no-undo.
    define variable ch-erro-webservice      as   character          no-undo.
    define variable ch-nome-arquivo         as   character          no-undo.
    define variable lg-erro-escrita-xml     as   logical            no-undo.
    define variable ch-resposta             as   character  init '' no-undo.
    define variable hd-request              as   handle             no-undo.
    define variable dt-output               as   datetime           no-undo.
    
    find first temp-parametro-entrada.       
    log-manager:write-message (substitute ('modo de comunicaÆo: &1', temp-parametro-entrada.ch-modo-envio-dados ),'DEBUG') no-error.
    
    if temp-parametro-entrada.ch-modo-envio-dados   = ENVIAR_DADOS_WEBSERVICE
    then do:
        log-manager:write-message (substitute ('enviando registros via webservice'),'DEBUG') no-error.
        
        assign lo-xml   = ConverteTempParaXml(hd-dataset).

        PreparaWebService().
        
        log-manager:write-message (substitute ('verificando quantidade de requisicoes abertas: &1', hd-web-service:async-request-count),'DEBUG') no-error.
        do while hd-web-service:async-request-count > 5:
            pause 1.
            process events.
        end.
        
        log-manager:write-message (substitute ('enviando dados ao webservice' ),'DEBUG') no-error.            
        run EnviarDadosEtapa in hd-progress-service 
                             asynchronous set hd-request 
                             event-procedure 'HandleProcedureReturn' (input temp-parametro-entrada.in-id-execucao, 
                                                                      input lo-xml, 
                                                                      output dt-output) no-error.
        if error-status:error
        then do:
            DispararException (substitute ('nao foi possivel realizar a chamada EnviarDadosTarefa: &1 - &2',
                                           error-status:get-number (1),
                                           error-status:get-message (1)), 0).
        end.
        // armazena na temp-table o handle da requisicao para que o objeto nao seja destruido e possa processasr o retorno. caso os handles sejam destruidos, 

        // a property hd-web-service:async-request-count nunca ser  atualizada com o resultado dos processamentos.

        create temp-request-handlers.
        assign temp-request-handlers.hd-request = hd-request.
        
    end.
    else do:
        log-manager:write-message (substitute ('enviando dados via arquivo' ),'DEBUG') no-error.
         
        
        assign ch-nome-arquivo = substitute ('&1/&2', temp-parametro-entrada.ch-caminho-gravacao-arquivos, GerarNomeArquivoTemporario("xml")).
        
        log-manager:write-message (substitute ('nome do arquivo: &1', ch-nome-arquivo ),'DEBUG') no-error.
        
        lg-erro-escrita-xml = hd-dataset:write-xml('file', ch-nome-arquivo, false, 'ISO8859-1', ?, false, false) no-error.
        
        if not lg-erro-escrita-xml 
        or error-status:error
        then do:
            DispararException (substitute ('erro ao escrever xml: &1', error-status:get-message (1)), 0).
        end.
    end.
    return yes.
end function.

function ConverteTempParaXml returns longchar 
    (hd-table-handle           as   handle):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define variable result as longchar no-undo.
    
    log-manager:write-message (substitute ('convertendo temp/dataset para xml '),'DEBUG') no-error.
       
    hd-table-handle:write-xml ("longchar",
                               result,
                               no, 
                               session:cpinternal,
                               ?,
                               no,
                               no).
    return result.
end function.



function FinalizarTarefa returns character 
    (in-id-task                     as   integer  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    

    define variable ch-resposta         as   character  no-undo.
    define variable lg-ok               as   logical    no-undo.
    define variable lo-xml              as   longchar   no-undo.

    find first temp-parametro-entrada.
    
    if temp-parametro-entrada.ch-modo-envio-dados   = ENVIAR_DADOS_WEBSERVICE
    then do:
        
        PreparaWebService().    
            
        do while hd-web-service:async-request-count > 0:
            pause 1.
            process events.
        end.
        
        assign lo-xml   = ConverteTempParaXml (dataset XML_EXECUCAODset:handle).
        
        run ReportarFinalizacaoEtapa in hd-progress-service (input  in-id-task,
                                                             input  lo-xml) no-error.
        if error-status:error
        then do:
            DispararException (substitute ('nao foi possivel realizar a chamada FinishTask: &1 - &2',
                               error-status:get-number (1),
                               error-status:get-message (1)), 0).
        end.
          
        hd-web-service:disconnect () no-error. 
        delete object hd-progress-service no-error.
        delete object hd-web-service no-error.
    end.
    else do: 
        
        define variable ch-nome-arquivo as   character  no-undo.
        
        assign ch-nome-arquivo  = substitute ('&1/&2', temp-parametro-entrada.ch-caminho-gravacao-arquivos, '.finish').
        output to value(ch-nome-arquivo).
            put skip.
        output close.
    end.
    

        
end function. 
          

/*------------------------------------------------------------------------
    File        : alertas-faturamento.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Thu Jan 11 14:37:58 BRST 2018
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

define temp-table XML_ALERTA no-undo
    namespace-uri "http://www.thealth.com.br/BillingAlert.xsd" 
    field CODIGO as character 
        xml-node-type "ATTRIBUTE" 
    field CHAVE_SISTEMA as character 
    field CHAVE_SISTEMA_CONTRATANTE as character 
    field CHAVE_SISTEMA_CONTRATO as character 
    field CHAVE_SISTEMA_BENEF as character 
    field CODIGO_UNIDADE_BENEF as integer 
    field CODIGO_CART_BENEF as character 
    field TITULO as character 
    field DESCRICAO as character 
    field VALOR as decimal 
    field ANO as integer 
    field MES as integer 
    field CHAVE_SISTEMA_FATURAMENTO as character .

define temp-table XML_DADOS_EXTRAS no-undo
    namespace-uri "http://www.thealth.com.br/BillingAlert.xsd" 
    field CAMPO as character 
    field VALOR as character 
    field XML_ALERTA_id as recid 
        xml-node-type "HIDDEN" .

define dataset XML_ALERTAS namespace-uri "http://www.thealth.com.br/BillingAlert.xsd" 
    for XML_ALERTA, XML_DADOS_EXTRAS
    parent-id-relation RELATION1 for XML_ALERTA, XML_DADOS_EXTRAS
        parent-id-field XML_ALERTA_id.




define variable CH_MENSAGEM_COPART_NAO_FATURADA
                                                as   character
                                                init "CoparticipaÆo em movimento liberado pelo RC e nÆo faturada" no-undo.
define variable CH_MENSAGEM_CONTRATO_SEM_NOTASERV   
                                                as   character  
                                                init "Contrato ativo no per¡odo mas sem nota de servio" no-undo.
define variable CH_MENSAGEM_NOTASERV_SEM_FATURA   
                                                as   character  
                                                init "Nota de servio nÆo possui fatura gerada" no-undo.
define variable CH_MENSAGEM_NOTASERV_VINCULADO_FATURA_INEXISTENTE   
                                                as   character  
                                                init "Nota de servio vinculado a fatura inexistente" no-undo.                                                
define variable CH_MENSAGEM_FATURA_NAO_INTEGRADA_FINANCEIRO 
                                                as   character  
                                                init "Fatura nÆo integrada no financeiro" no-undo.                                                       
define variable CH_MENSAGEM_FATURA_VINCULADO_TITULO_INEXISTENTE
                                                as   character  
                                                init "Fatura vinculada a t¡tulo inexistente" no-undo.                                                                                            
define variable CH_MENSAGEM_MOVIMENTO_CUSTO_NAO_FATURADO
                                                as   character  
                                                init "Movimento de custo operacional liberado no contas e nÆo faturado" no-undo.                                                                                            
define variable CH_MENSAGEM_MOVIMENTO_INTERCAMBIO_NAO_FATURADO
                                                as   character  
                                                init "Movimento de intercmbio liberado no contas e nÆo faturado" no-undo.                                                                                            

/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
  

define variable lg-possui-espec                 as   logical        no-undo.
define variable hd-especifico                   as   handle         no-undo.
 
/* **********************  Internal Procedures  *********************** */


procedure Executa:
    define input  parameter table for temp-parametro-entrada.
    define input  parameter table for temp-parametro-periodo.

    define variable ch-referencia               as   character  no-undo.
    define variable in-ano                      as   integer    no-undo.
    define variable in-mes                      as   integer    no-undo.
    define variable dt-base                     as   date       no-undo.
    
    find first temp-parametro-entrada.
    find first paramecp no-lock.
    
    if search ('espec-alertas-faturamento-co.p') <> ?
    or search ('espec-alertas-faturamento-co.r') <> ?
    then do:        

        lg-possui-espec = yes.
        
        run espec-alertas-faturamento-co.p persistent set hd-especifico.
        
    end.
    
    for each temp-parametro-periodo:
        
        run ProcessaMesAno (input  temp-parametro-periodo.in-mes,
                            input  temp-parametro-periodo.in-ano).                            
        
        run ProcessaCustoNaoFaturado (input  temp-parametro-periodo.in-mes,
                                      input  temp-parametro-periodo.in-ano).                            
                            
    end.
end procedure.

procedure LeInsumos:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define input  parameter in-periodo-ano          as   integer    no-undo.
    define input  parameter in-periodo-numero       as   integer    no-undo.
    define input  parameter in-ano                  as   integer    no-undo.
    define input  parameter in-mes                  as   integer    no-undo.
    
    define variable lg-gerar-alerta             as   logical    no-undo.

    for each mov-insu no-lock
       where mov-insu.cd-unidade                = paramecp.cd-unimed
         and mov-insu.in-liberado-contas        = "1"
         and mov-insu.in-liberado-pagto         = "1"
         and mov-insu.dt-anoref                 = in-periodo-ano
         and mov-insu.nr-perref                 = in-periodo-numero
         and mov-insu.in-liberado-faturamento   = "0"
         and mov-insu.cd-forma-pagto-cob        = 2:
                  
        if  mov-insu.cd-tipo-cob           <> 0
        and mov-insu.cd-tipo-cob           <> 1
        and mov-insu.cd-tipo-cob           <> 2
        then next.                     
            
        if available propost then release propost.            
        if available contrat then release contrat.
        if available usuario then release usuario.
             
        if mov-insu.cd-unidade-carteira = paramecp.cd-unimed
        then do:
            find first propost no-lock
                 where propost.cd-modalidade    = mov-insu.cd-modalidade
                   and propost.nr-ter-adesao    = mov-insu.nr-ter-adesao
                       no-error.
            if not available propost then next.                       
                       
            find first contrat no-lock
                 where contrat.cd-contratante   = propost.cd-contratante
                       no-error.      
            if not available contrat then next.
                 
            find first usuario no-lock
                 where usuario.cd-modalidade    = mov-insu.cd-modalidade
                   and usuario.nr-ter-adesao    = mov-insu.nr-ter-adesao
                   and usuario.cd-usuario       = mov-insu.cd-usuario
                       no-error.     
            if not available usuario then next.                                                    
        end.         
        else next.
        
        if lg-possui-espec
        then do:
            
            run ValidaInsumo in hd-especifico (input  recid (mov-insu),
                                                     output lg-gerar-alerta).
                                                     
            if not lg-gerar-alerta 
            then do:
                log-manager:write-message (substitute ('registro sinalizado para nÃ£o gerar alerta pelo especifico do cliente'),'DEBUG').
                next.
            end.                                                     
            
        end. 
                    
        create XML_ALERTA.              
        assign XML_ALERTA.CHAVE_SISTEMA             = 'CNF' + RegistroPrimary (buffer mov-insu:handle)
               XML_ALERTA.CODIGO                    = substitute ('&1/&2', usuario.cd-modalidade, usuario.nr-ter-adesao)
/*               XML_ALERTA.CODIGO                    = substitute ('&1/&2/&3/&4/&5/&6/&7/&8',     */
/*                                                                  mov-insu.cd-unidade,           */
/*                                                                  mov-insu.cd-unidade-prestadora,*/
/*                                                                  mov-insu.cd-transacao,         */
/*                                                                  mov-insu.nr-serie-doc-original,*/
/*                                                                  mov-insu.nr-doc-original,      */
/*                                                                  mov-insu.nr-doc-sistema,       */
/*                                                                  mov-insu.nr-processo,          */
/*                                                                  mov-insu.nr-seq-digitacao)     */
               XML_ALERTA.TITULO                    = CH_MENSAGEM_MOVIMENTO_CUSTO_NAO_FATURADO
               XML_ALERTA.DESCRICAO                 = substitute ("Insumo &1&2 nao foi faturado",
                                                                  string (mov-insu.cd-tipo-insumo, '99'),
                                                                  string (mov-insu.cd-insumo, '99999999'))
               XML_ALERTA.ANO                       = in-ano
               XML_ALERTA.MES                       = in-mes   
               XML_ALERTA.CODIGO_UNIDADE_BENEF      = mov-insu.cd-unidade-carteira
               XML_ALERTA.CODIGO_CART_BENEF         = string(mov-insu.cd-carteira-usuario, '9999999999999')
               XML_ALERTA.CHAVE_SISTEMA_BENEF       = RegistroPrimary (buffer usuario:handle)                                      
               XML_ALERTA.CHAVE_SISTEMA_CONTRATO    = RegistroPrimary (buffer propost:handle) 
               XML_ALERTA.CHAVE_SISTEMA_CONTRATANTE = RegistroPrimary (buffer contrat:handle) 
               XML_ALERTA.CHAVE_SISTEMA_FATURAMENTO = ""
               XML_ALERTA.VALOR                     = mov-insu.vl-real-pago.           

        create XML_DADOS_EXTRAS.
        assign XML_DADOS_EXTRAS.CAMPO               = 'CÃ³digo Glosa'
               XML_DADOS_EXTRAS.VALOR               = string (mov-insu.cd-cod-glo)
               XML_DADOS_EXTRAS.XML_ALERTA_id       = recid (XML_ALERTA). 

        create XML_DADOS_EXTRAS.
        assign XML_DADOS_EXTRAS.CAMPO               = 'Forma Pagamento'
               XML_DADOS_EXTRAS.VALOR               = string (mov-insu.cd-forma-pagto)
               XML_DADOS_EXTRAS.XML_ALERTA_id       = recid (XML_ALERTA). 
    
        create XML_DADOS_EXTRAS.
        assign XML_DADOS_EXTRAS.CAMPO               = 'Forma CobranÃ§a'
               XML_DADOS_EXTRAS.VALOR               = string (mov-insu.cd-forma-pagto-cob)
               XML_DADOS_EXTRAS.XML_ALERTA_id       = recid (XML_ALERTA). 
                   
        create XML_DADOS_EXTRAS.
        assign XML_DADOS_EXTRAS.CAMPO               = 'Tipo Cob'
               XML_DADOS_EXTRAS.VALOR               = string (mov-insu.cd-tipo-cob)
               XML_DADOS_EXTRAS.XML_ALERTA_id       = recid (XML_ALERTA). 
                 
    end.   

end procedure.

procedure LeProcedimento:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define input  parameter in-periodo-ano          as   integer    no-undo.
    define input  parameter in-periodo-numero       as   integer    no-undo.
    define input  parameter in-ano                  as   integer    no-undo.
    define input  parameter in-mes                  as   integer    no-undo.
    
    define variable lg-gerar-alerta                 as   logical    no-undo.
    
    for each moviproc no-lock 
       where moviproc.cd-unidade                = paramecp.cd-unimed
         and moviproc.in-liberado-contas        = "1"
         and moviproc.in-liberado-pagto         = "1"
         and moviproc.dt-anoref                 = perimovi.dt-anoref
         and moviproc.nr-perref                 = perimovi.nr-perref             
         and moviproc.in-liberado-faturamento   = "0"
         and moviproc.cd-forma-pagto-cob        = 2:
             
        if  moviproc.cd-tipo-cob           <> 0
        and moviproc.cd-tipo-cob           <> 1
        and moviproc.cd-tipo-cob           <> 2
        then next.             
            
        if available propost then release propost.            
        if available contrat then release contrat.
        if available usuario then release usuario.
             
        if moviproc.cd-unidade-carteira = paramecp.cd-unimed
        then do:
            find first propost no-lock
                 where propost.cd-modalidade    = moviproc.cd-modalidade
                   and propost.nr-ter-adesao    = moviproc.nr-ter-adesao
                       no-error.
            if not available propost then next.                       
                       
            find first contrat no-lock
                 where contrat.cd-contratante   = propost.cd-contratante
                       no-error.
            if not available contrat then next.                       
                                              
            find first usuario no-lock
                 where usuario.cd-modalidade    = mov-insu.cd-modalidade
                   and usuario.nr-ter-adesao    = mov-insu.nr-ter-adesao
                   and usuario.cd-usuario       = mov-insu.cd-usuario
                       no-error.
            if not available usuario then next.                               
        end.        
        else next.
        
        if lg-possui-espec
        then do:
            
            run ValidaProcedimento in hd-especifico (input  recid (moviproc),
                                                     output lg-gerar-alerta).
                                                     
            if not lg-gerar-alerta 
            then do:
                log-manager:write-message (substitute ('registro sinalizado para nÃ£o gerar alerta pelo especifico do cliente'),'DEBUG').
                next.
            end.                                                     
            
        end.         

        create XML_ALERTA.              
        assign XML_ALERTA.CHAVE_SISTEMA             = 'CNF' + RegistroPrimary (buffer moviproc:handle)
               XML_ALERTA.CODIGO                    = substitute ('&1/&2', usuario.cd-modalidade, usuario.nr-ter-adesao)
        
/*               XML_ALERTA.CODIGO                    = substitute ('&1/&2/&3/&4/&5/&6/&7/&8',     */
/*                                                                  moviproc.cd-unidade,           */
/*                                                                  moviproc.cd-unidade-prestadora,*/
/*                                                                  moviproc.cd-transacao,         */
/*                                                                  moviproc.nr-serie-doc-original,*/
/*                                                                  moviproc.nr-doc-original,      */
/*                                                                  moviproc.nr-doc-sistema,       */
/*                                                                  moviproc.nr-processo,          */
/*                                                                  moviproc.nr-seq-digitacao)     */
               XML_ALERTA.TITULO                    = CH_MENSAGEM_MOVIMENTO_CUSTO_NAO_FATURADO
               XML_ALERTA.DESCRICAO                 = substitute ("Procedimento &1&2&3&4 nao foi faturado",
                                                                  string (moviproc.cd-esp-amb, '99'),
                                                                  string (moviproc.cd-grupo-proc-amb, '99'),
                                                                  string (moviproc.cd-procedimento, '999'),
                                                                  string (moviproc.dv-procedimento, '9'))
               XML_ALERTA.ANO                       = in-ano
               XML_ALERTA.MES                       = in-mes   
               XML_ALERTA.CODIGO_UNIDADE_BENEF      = moviproc.cd-unidade-carteira
               XML_ALERTA.CODIGO_CART_BENEF         = string (moviproc.cd-carteira-usuario, '9999999999999')
               XML_ALERTA.CHAVE_SISTEMA_BENEF       = RegistroPrimary (buffer usuario:handle)                                                                             
               XML_ALERTA.CHAVE_SISTEMA_CONTRATO    = RegistroPrimary (buffer propost:handle) 
               XML_ALERTA.CHAVE_SISTEMA_CONTRATANTE = RegistroPrimary (buffer contrat:handle) 
               XML_ALERTA.CHAVE_SISTEMA_FATURAMENTO = ""
               XML_ALERTA.VALOR                     = moviproc.vl-real-pago.           
        
        create XML_DADOS_EXTRAS.
        assign XML_DADOS_EXTRAS.CAMPO               = 'CÃ³digo Glosa'
               XML_DADOS_EXTRAS.VALOR               = string (moviproc.cd-cod-glo)
               XML_DADOS_EXTRAS.XML_ALERTA_id       = recid (XML_ALERTA). 

        create XML_DADOS_EXTRAS.
        assign XML_DADOS_EXTRAS.CAMPO               = 'Forma Pagamento'
               XML_DADOS_EXTRAS.VALOR               = string (moviproc.cd-forma-pagto)
               XML_DADOS_EXTRAS.XML_ALERTA_id       = recid (XML_ALERTA). 
    
        create XML_DADOS_EXTRAS.
        assign XML_DADOS_EXTRAS.CAMPO               = 'Forma CobranÃ§a'
               XML_DADOS_EXTRAS.VALOR               = string (moviproc.cd-forma-pagto-cob)
               XML_DADOS_EXTRAS.XML_ALERTA_id       = recid (XML_ALERTA). 
               
        create XML_DADOS_EXTRAS.
        assign XML_DADOS_EXTRAS.CAMPO               = 'Tipo Cob'
               XML_DADOS_EXTRAS.VALOR               = string (moviproc.cd-tipo-cob)
               XML_DADOS_EXTRAS.XML_ALERTA_id       = recid (XML_ALERTA). 
        
    end.   

end procedure.

procedure ProcessaCustoNaoFaturado:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define input  parameter in-mes          as   integer        no-undo.
    define input  parameter in-ano          as   integer        no-undo.
    
    define variable dt-inicio               as   date           no-undo.
    define variable dt-fim                  as   date           no-undo.
    
    assign dt-inicio    = date (in-mes, 1, in-ano)
           dt-fim       = UltimoDiaMes (in-ano, in-mes).

    log-manager:write-message (substitute ('periodo: entre &1 e &2', dt-inicio, dt-fim ),'DEBUG').           
           
    for each perimovi no-lock:

        if perimovi.dt-fim-per      < dt-inicio then next.
        if perimovi.dt-inicio-per   > dt-fim    then next.
        
        log-manager:write-message (substitute ('lendo periodo &1/&2', perimovi.dt-anoref, perimovi.nr-perref ),'DEBUG').
        
        run LeProcedimento (input  perimovi.dt-anoref,
                            input  perimovi.nr-perref,
                            input  in-ano,
                            input  in-mes).            

        run LeInsumos (input  perimovi.dt-anoref,
                       input  perimovi.nr-perref,
                       input  in-ano,
                       input  in-mes).            

    end.           
    
    EnviarDados (dataset XML_ALERTAS:handle).
    dataset XML_ALERTAS:empty-dataset (). 
end procedure.

procedure ProcessaMesAno:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define input        parameter in-mes                as   integer        no-undo.
    define input        parameter in-ano                as   integer        no-undo.
    
    define variable dt-inicial                          as   date       no-undo.
    define variable dt-final                            as   date       no-undo.
    define variable in-codigo-contratante               as   integer    no-undo.
    define variable dc-valor                            as   decimal    no-undo.    
    define buffer   buf-contrat-orig                    for  contrat.

    assign dt-inicial   = date (in-mes, 1, in-ano)
           dt-final     = UltimoDiaMes(in-ano, in-mes).

    
    for each notaserv no-lock
       where notaserv.cd-modalidade     > 0
         and notaserv.nr-ter-adesao     > 0
         and notaserv.aa-referencia     = in-ano
         and notaserv.mm-referencia     = in-mes
         and (  notaserv.in-tipo-nota   = 1
             or notaserv.in-tipo-nota   = 8),
       first propost no-lock
       where propost.cd-modalidade      = notaserv.cd-modalidade
         and propost.nr-ter-adesao      = notaserv.nr-ter-adesao,
       first ter-ade no-lock
       where ter-ade.cd-modalidade      = propost.cd-modalidade
         and ter-ade.nr-ter-adesao      = propost.nr-ter-adesao:

        
        if ter-ade.in-contratante-custo-op  = 0
        then find first contrat no-lock
                  where contrat.cd-contratante  = propost.cd-contratante.
        else find first contrat no-lock
                  where contrat.cd-contratante  = propost.cd-contrat-origem.          
        
        if notaserv.nr-fatura   = 0
        then do:
            
            create XML_ALERTA.              
            assign XML_ALERTA.CHAVE_SISTEMA             = "CO" + RegistroPrimary (buffer propost:handle)
                   XML_ALERTA.CODIGO                    = substitute ('&1/&2', propost.cd-modalidade, propost.nr-ter-adesao)
                   XML_ALERTA.TITULO                    = CH_MENSAGEM_NOTASERV_SEM_FATURA
                   XML_ALERTA.DESCRICAO                 = substitute ("Termo: &1, perÃ­odo: &2/&3, espÃ©cie &4, seq: &5, emissÃ£o: &6, vencimento: &7, ult fat: &8/&9",
                                                                      string (ter-ade.cd-modalidade, '99') + '/' + string (ter-ade.nr-ter-adesao), 
                                                                      in-mes,
                                                                      in-ano,
                                                                      notaserv.cd-especie,
                                                                      notaserv.nr-sequencia,
                                                                      notaserv.dt-emissao,
                                                                      notaserv.dt-vencimento,
                                                                      ter-ade.mm-ult-fat,
                                                                      ter-ade.aa-ult-fat)
                   XML_ALERTA.ANO                       = in-ano
                   XML_ALERTA.MES                       = in-mes   
                   XML_ALERTA.CHAVE_SISTEMA_CONTRATO    = RegistroPrimary (buffer propost:handle)
                   XML_ALERTA.CHAVE_SISTEMA_CONTRATANTE = RegistroPrimary (buffer contrat:handle)       
                   XML_ALERTA.CHAVE_SISTEMA_FATURAMENTO = RegistroPrimary (buffer notaserv:handle)
                   XML_ALERTA.VALOR                     = notaserv.vl-total .     
            next.                 
        end.
        
        find first fatura no-lock
             where fatura.cd-contratante   = contrat.cd-contratante
               and fatura.nr-fatura        = notaserv.nr-fatura
                   no-error.
                   
        if not available fatura                             
        then do:
            
            create XML_ALERTA.                          
            assign XML_ALERTA.CHAVE_SISTEMA             = "CO" + RegistroPrimary(buffer propost:handle)
                   XML_ALERTA.CODIGO                    = substitute ('&1/&2', propost.cd-modalidade, propost.nr-ter-adesao)
                   XML_ALERTA.TITULO                    = CH_MENSAGEM_NOTASERV_VINCULADO_FATURA_INEXISTENTE
                   XML_ALERTA.DESCRICAO                 = substitute ("Termo: &1, perÃ­odo: &2/&3, espÃ©cie &4, seq: &5, emissÃ£o: &6, vencimento: &7, ult fat: &8/&9",
                                                                      string (ter-ade.cd-modalidade, '99') + '/' + string (ter-ade.nr-ter-adesao), 
                                                                      in-mes,
                                                                      in-ano,
                                                                      notaserv.cd-especie,
                                                                      notaserv.nr-sequencia,
                                                                      notaserv.dt-emissao,
                                                                      notaserv.dt-vencimento,
                                                                      ter-ade.mm-ult-fat,
                                                                      ter-ade.aa-ult-fat)
                   XML_ALERTA.ANO                       = in-ano
                   XML_ALERTA.MES                       = in-mes   
                   XML_ALERTA.CHAVE_SISTEMA_CONTRATO    = RegistroPrimary (buffer propost:handle)
                   XML_ALERTA.CHAVE_SISTEMA_CONTRATANTE = RegistroPrimary (buffer contrat:handle)       
                   XML_ALERTA.CHAVE_SISTEMA_FATURAMENTO = RegistroPrimary (buffer notaserv:handle)
                   XML_ALERTA.VALOR                     = notaserv.vl-total . 
            next.                
        
        end.
               
        if fatura.cd-sit-fatu   = 10
        or fatura.cd-sit-fatu   = 20
        or fatura.nr-titulo-acr = ''
        then do:
            create XML_ALERTA.                          
            assign XML_ALERTA.CHAVE_SISTEMA             = "CO" + RegistroPrimary(buffer propost:handle)
                   XML_ALERTA.CODIGO                    = substitute ('&1/&2', propost.cd-modalidade, propost.nr-ter-adesao)
                   XML_ALERTA.TITULO                    = CH_MENSAGEM_FATURA_NAO_INTEGRADA_FINANCEIRO
                   XML_ALERTA.DESCRICAO                 = substitute ("Termo: &1, perÃ­odo: &2/&3, espÃ©cie &4, seq: &5, emissÃ£o: &6, vencimento: &7, ult fat: &8/&9",
                                                                      string (ter-ade.cd-modalidade, '99') + '/' + string (ter-ade.nr-ter-adesao), 
                                                                      in-mes,
                                                                      in-ano,
                                                                      notaserv.cd-especie,
                                                                      notaserv.nr-sequencia,
                                                                      notaserv.dt-emissao,
                                                                      notaserv.dt-vencimento,
                                                                      ter-ade.mm-ult-fat,
                                                                      ter-ade.aa-ult-fat)
                   XML_ALERTA.ANO                       = in-ano
                   XML_ALERTA.MES                       = in-mes   
                   XML_ALERTA.CHAVE_SISTEMA_CONTRATO    = RegistroPrimary (buffer propost:handle)
                   XML_ALERTA.CHAVE_SISTEMA_CONTRATANTE = RegistroPrimary (buffer contrat:handle)       
                   XML_ALERTA.CHAVE_SISTEMA_FATURAMENTO = RegistroPrimary (buffer notaserv:handle)
                   XML_ALERTA.VALOR                     = notaserv.vl-total . 
            next. 
        end.         
        
        find first tit_acr no-lock  
             where tit_acr.cod_estab       = fatura.cod-estabel
               and tit_acr.cod_espec_docto = fatura.cd-especie
               and tit_acr.cod_ser_docto   = substring (fatura.serie-nf, 1, 3)
               and tit_acr.cod_tit_acr     = fatura.nr-titulo-acr
               and (   string (int(tit_acr.cod_parcela), '99')  =  string (fatura.parcela, "99")
                    or (    fatura.parcela   = 0
                        and tit_acr.cod_parcela = ''
                        ))
                   no-error.    
         
        if not available tit_acr
        then do:
            create XML_ALERTA.                          
            assign XML_ALERTA.CHAVE_SISTEMA             = RegistroPrimary (buffer propost:handle)
                   XML_ALERTA.CODIGO                    = substitute ('&1/&2', propost.cd-modalidade, propost.nr-ter-adesao)
                   XML_ALERTA.TITULO                    = CH_MENSAGEM_FATURA_VINCULADO_TITULO_INEXISTENTE
                   XML_ALERTA.DESCRICAO                 = substitute ("Termo: &1, perÃ­odo: &2/&3, espÃ©cie &4, seq: &5, emissÃ£o: &6, vencimento: &7, ult fat: &8/&9",
                                                                      string (ter-ade.cd-modalidade, '99') + '/' + string (ter-ade.nr-ter-adesao), 
                                                                      in-mes,
                                                                      in-ano,
                                                                      notaserv.cd-especie,
                                                                      notaserv.nr-sequencia,
                                                                      notaserv.dt-emissao,
                                                                      notaserv.dt-vencimento,
                                                                      ter-ade.mm-ult-fat,
                                                                      ter-ade.aa-ult-fat)
                   XML_ALERTA.ANO                       = in-ano
                   XML_ALERTA.MES                       = in-mes   
                   XML_ALERTA.CHAVE_SISTEMA_CONTRATO    = RegistroPrimary (buffer propost:handle)
                   XML_ALERTA.CHAVE_SISTEMA_CONTRATANTE = RegistroPrimary (buffer contrat:handle)       
                   XML_ALERTA.CHAVE_SISTEMA_FATURAMENTO = RegistroPrimary (buffer notaserv:handle)
                   XML_ALERTA.VALOR                     = notaserv.vl-total .
                   
            next. 
        end.
    end.           

    EnviarDados (dataset XML_ALERTAS:handle).
    dataset XML_ALERTAS:empty-dataset (). 
                      
end procedure.
