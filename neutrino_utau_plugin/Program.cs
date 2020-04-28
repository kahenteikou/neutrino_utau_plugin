using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Win32;

namespace neutrino_utau_plugin
{
    class Program
    {
        [STAThread]
        static void Main(string[] args)
        {   

            if(args.Length < 1)
            {
                System.Console.WriteLine("ERROR ! You must set filename.");
                return;
            }
            UST_MUSICXML_LIB.ustclass ustkun = new UST_MUSICXML_LIB.ustclass(args[0]);
            SaveFileDialog saveFileDialog = new SaveFileDialog();
            saveFileDialog.Filter = "MusicXML (*.musicxml)|*.musicxml|XML (*.xml)|*.xml|すべてのファイル (*.*)|*.*";
            
            if (saveFileDialog.ShowDialog()==true)
            {
                using(FileStream fskun=new FileStream(saveFileDialog.FileName, FileMode.Create))
                {
                    ustkun.Write_XML(fskun);
                }
            }
            //デバッグ用
            /*
            using(MemoryStream memstr=new MemoryStream())
            {
                ustkun.Write_XML(memstr);
                StreamReader sr = new StreamReader(memstr,Encoding.UTF8);
                sr.BaseStream.Seek(0, SeekOrigin.Begin);
                Console.WriteLine(sr.ReadToEnd());
            }*/
        }
    }
}
