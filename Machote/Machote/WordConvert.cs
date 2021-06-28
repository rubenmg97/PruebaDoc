using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Office.Interop.Word;
using System.IO;
using System.Xml.Linq;

namespace Machote
{
    public class WordConvert
    {
        public static void Word(String path)
        {
            object fileName = "Rtf1";
            Application wordApp = new Application { Visible = false };
            Document aDoc = wordApp.Documents.Open(ref fileName, ReadOnly: false, Visible: true);

            aDoc = document;
            aDoc;

            Paragraph oPara1 = new Paragraph(document);
            oPara1.Content.LoadText("here goes the rtf string", LoadOptions.RtfDefault);

            string text = File.ReadAllText(path);
            text = text.Replace(match, newValue);

            ///
               Dim BD As New ProdeskNet.BD.clsManejaBD
               Dim Stream As MemoryStream
               Dim pdf As New PdfMetamorphosis()
               Dim RTFpath As String = Server.MapPath("..\Documentos\Autorización_para_solicitar_Reportes_de_Crédito" + Request("IdFolio") + ".rtf")
               Dim PDFpath As String = Server.MapPath("..\Documentos\Autorización_para_solicitar_Reportes_de_Crédito" + Request("IdFolio") + ".pdf")
              
               //Dim dsResult As New DataSet
               //'Dim dsResult = BD.EjecutarQuery("EXEC stpREP_obtenerRptAutCredito @ID_SECCCERO = 1006, @OP = 1")
               //BD.AgregaParametro("@ID_SECCCERO", ProdeskNet.BD.TipoDato.Entero, Request("IdFolio"), False)
               //BD.AgregaParametro("@OP", ProdeskNet.BD.TipoDato.Entero, 1, False)
               //dsResult = BD.EjecutaStoredProcedure("stpREP_obtenerRptAutCredito")

               Dim RFT As String
               RFT = dsResult.Tables(0).Rows(0)("RFT").ToString()

               Stream = New MemoryStream(Encoding.UTF8.GetBytes(RFT))
               File.WriteAllBytes(RTFpath, Stream.ToArray())
              
               //pdf.Serial = "10347377383"
               pdf.RtfToPdfConvertFile(RTFpath, PDFpath)
               File.Delete(RTFpath)
               ScriptManager.RegisterStartupScript(Me.Page, GetType(String), "CierraVentana", "(function(){  window.open('', '_self', ''); window.close(); })();", True)
            ////
        }


        public static void ex1(String rtf)
        {
            //using Word = Microsoft.Office.Interop.Word;

            object fileName = Path.Combine(@"D:\VS2010Workspace\WordDocReplaceTest\WordDocReplaceTest\bin\Release", "TestDoc.docx");
            object missing = System.Reflection.Missing.Value;
            Microsoft.Office.Interop.Word.Application wordApp = new Microsoft.Office.Interop.Word.Application { Visible = false };

            Microsoft.Office.Interop.Word.Document aDoc = wordApp.Documents.Open(ref fileName, ReadOnly: false, Visible: true);

            aDoc.Activate();

            Microsoft.Office.Interop.Word.Find fnd = wordApp.ActiveWindow.Selection.Find;

            fnd.ClearFormatting();
            fnd.Replacement.ClearFormatting();
            fnd.Forward = true;
            fnd.Wrap = Microsoft.Office.Interop.Word.WdFindWrap.wdFindContinue;

            fnd.Text = "{替换前内容}";
            fnd.Replacement.Text = "替换后内容-updated";

            fnd.Execute(Replace: Microsoft.Office.Interop.Word.WdReplace.wdReplaceAll);
            aDoc.Save();

            aDoc.Close(ref missing, ref missing, ref missing);
            wordApp.Quit(ref missing, ref missing, ref missing);


            //
            //WdR Document 
            //WdExportFormat.wdExportFormatPDF();
         }

        static void OpenFile(string filepath, int selectionstart)
        {
            cache["lastdir"] = Path.GetDirectoryName(filepath);
            string fileext = Path.GetExtension(filepath).ToLower();
            if (fileext == ".doc" || fileext == ".docx")
            {
                object oMissing = System.Reflection.Missing.Value;
                object isReadOnly = true;
                Microsoft.Office.Interop.Word._Application oWord;
                Microsoft.Office.Interop.Word._Document oDoc;

                oWord = new Microsoft.Office.Interop.Word.Application();
                oWord.Visible = false;
                object fileName = filepath;
                oDoc = oWord.Documents.Open(ref fileName,
                ref oMissing, ref isReadOnly, ref oMissing, ref oMissing, ref oMissing,
                ref oMissing, ref oMissing, ref oMissing, ref oMissing, ref oMissing,
                ref oMissing, ref oMissing, ref oMissing, ref oMissing, ref oMissing);

                this.rtbxMain.Text = oDoc.Content.Text;
                oDoc.Close(ref oMissing, ref oMissing, ref oMissing);
                oWord.Quit(ref oMissing, ref oMissing, ref oMissing);
                if (MessageBox.Show("转换为RTF文档并重新打开?", "转换格式", MessageBoxButtons.YesNo) == DialogResult.Yes)
                {
                    string newrtfpath = filepath + ".rtf";
                    this.rtbxMain.SaveFile(newrtfpath, RichTextBoxStreamType.RichText);
                    MessageBox.Show("转换为rtf成功.\r\n保存位置:" + newrtfpath, "转换格式");
                    OpenFile(newrtfpath, selectionstart);
                    return;
                }
            }
            else
            {
                FileStream fs = File.Open(filepath, FileMode.Open, FileAccess.Read);
                StreamReader sr = new StreamReader(fs, Encoding.Default, true);

                if (fileext == ".rtf")
                {
                    this.rtbxMain.Rtf = sr.ReadToEnd();
                    this.rtbxMain.Font = new Font("微软雅黑", 14f);
                }
                else
                {
                    rtbxMain.Text = sr.ReadToEnd();
                }
                sr.Close();
                fs.Close();
                fs.Dispose();
                sr.Dispose();
            }
            rtbxMain.SelectionStart = selectionstart;
            currentfilepath = filepath;
            this.Text = Path.GetFileNameWithoutExtension(currentfilepath);
            this.Icon = ((System.Drawing.Icon)(new System.ComponentModel.ComponentResourceManager(typeof(MainForm)).GetObject("$this.Icon")));
            tsmiReplaceWindowsTitle.Text = "隐藏标题";
            this.tsmiCurrentFilename.Text = this.Text;
            this.notifyIcon1.Text = this.Text;
        }


        public static void RtfWord()
        {
            string filePath = @"c:\rawRtfText.rtf";

            //write the raw RTF string to a text file.
            System.IO.StreamWriter rawTextFile = new System.IO.StreamWriter(filePath, false);
            string str = @"{\rtf1\ansi\ansicpg1252\uc1\deff0{\fonttbl{\f0\fnil\fcharset0\fprq2 Arial;}{\f1\fswiss\fcharset0\fprq2 Arial;}{\f2\froman\fcharset2\fprq2 Symbol;}}{\colortbl;}{\stylesheet{\s0\itap0\nowidctlpar\f0\fs24 [Normal];}{\*\cs10\additive Default Paragraph Font;}}{\*\generator TX_RTF32 17.0.540.502;}\paperw12240\paperh15840\margl1138\margt1138\margr1138\margb1138\deftab1134\widowctrl\formshade\sectd\headery720\footery720\pgwsxn12240\pghsxn15840\marglsxn1138\margtsxn1138\margrsxn1138\margbsxn1138\pgbrdropt32\pard\itap0\nowidctlpar\plain\f1\fs20 test1\par }";
            rawTextFile.Write(str);
            rawTextFile.Close();

            //now open the RTF file using word.
            Microsoft.Office.Interop.Word.Application msWord = new Microsoft.Office.Interop.Word.Application();
            msWord.Visible = false;
            Microsoft.Office.Interop.Word.Document wordDoc = msWord.Documents.Open(filePath);

            //after manipulating the word doc, save it as a word doc.
            object oMissing = System.Reflection.Missing.Value;
            wordDoc.SaveAs(@"c:\RtfConvertedToWord.doc", ref oMissing, ref oMissing, ref oMissing, ref oMissing, ref oMissing, ref oMissing, ref oMissing, ref oMissing, ref oMissing, ref oMissing, ref oMissing, ref oMissing, ref oMissing, ref oMissing, ref oMissing);
        }

//        For future references, if anyone is interested I found alternative here:
//https://code.msdn.microsoft.com/Word-Document-Editor-in-d97fd70b
//In short it uses the following to insert the rtf string in the document:
//Paragraph oPara1 = new Paragraph(document);
//        oPara1.Content.LoadText("here goes the rtf string", LoadOptions.RtfDefault);
//The sample uses this Word component for .NET that has an easy to use API for processing the RTF content in C#.
    }
}
