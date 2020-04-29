using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net.NetworkInformation;
using System.Runtime.Remoting;
using System.Runtime.Remoting.Channels;
using System.Runtime.Remoting.Channels.Ipc;
using System.Runtime.Remoting.Services;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Win32;
using Newtonsoft.Json;
using wrappe_connect;

namespace neutrino_utau_plugin
{
    class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            string appdatapath = System.Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "\\neutrino_utau_plugin";
            if (args.Length < 1)
            {
                System.Console.WriteLine("ERROR ! You must set filename.");
                return;
            }
            if (!Directory.Exists(appdatapath))
            {
                Directory.CreateDirectory(appdatapath);
            }
            wrapper_connect settingkun = new wrapper_connect();
            if(File.Exists(appdatapath + "\\settings.json"))
            {
                JsonSerializer jser = new JsonSerializer();
                using(FileStream fs=new FileStream(appdatapath + "\\settings.json", FileMode.Open))
                {
                    using(StreamReader sr=new StreamReader(fs, Encoding.UTF8))
                    {
                        using(JsonTextReader jr=new JsonTextReader(sr))
                        {
                            settingkun =jser.Deserialize<wrapper_connect>(jr);
                            settingkun.no_data = false;
                        }
                    }
                }
            }
            if (settingkun.no_data)
            {

                SettingsDialog settingsDialog = new SettingsDialog(settingkun);
                settingsDialog.cancel_enable = false;
                settingsDialog.ShowDialog();
                settingkun = settingsDialog.wrcon;

                JsonSerializer jser = new JsonSerializer();
                using(FileStream fskun=new FileStream(appdatapath + "\\settings.json", FileMode.OpenOrCreate)){
                    using(StreamWriter sw=new StreamWriter(fskun, Encoding.UTF8))
                    {
                        using (JsonTextWriter jsw = new JsonTextWriter(sw))
                        {
                            jser.Serialize(jsw, settingkun);
                            jsw.Flush();
                        }
                    }
                }
            }
            if (args[0].Equals("--setting")){

                SettingsDialog settingsDialog = new SettingsDialog(settingkun);
                settingsDialog.ShowDialog();
                settingkun = settingsDialog.wrcon;
                JsonSerializer jser = new JsonSerializer();
                using (FileStream fskun = new FileStream(appdatapath + "\\settings.json", FileMode.OpenOrCreate))
                {
                    using (StreamWriter sw = new StreamWriter(fskun, Encoding.UTF8))
                    {
                        using (JsonTextWriter jsw = new JsonTextWriter(sw))
                        {
                            jser.Serialize(jsw, settingkun);
                            jsw.Flush();
                        }
                    }
                }
            }
            /*
            SaveFileDialog saveFileDialog = new SaveFileDialog();
            saveFileDialog.Filter = "MusicXML (*.musicxml)|*.musicxml|XML (*.xml)|*.xml|すべてのファイル (*.*)|*.*";
            
            if (saveFileDialog.ShowDialog()==true)
            {
                using(FileStream fskun=new FileStream(saveFileDialog.FileName, FileMode.Create))
                {
                    ustkun.Write_XML(fskun);
                }
            }
            */
            ProjectNameInput pri = new ProjectNameInput();
            pri.ShowDialog();

            string xml_fname = settingkun.neutrino_dirname;
            xml_fname = xml_fname.TrimEnd('\\');
            xml_fname = xml_fname + "\\score\\musicxml\\" + pri.nameD + ".musicxml";
            string xml_fname_t = xml_fname + "_tmp";
            run_process(System.AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\') + "\\perl\\bin\\perl.exe","\""+ System.AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\') + "\\perl\\utau2sinsy.pl\" "+   "\"" + args[0].Replace("\"", "") + "\" " + "\"" + xml_fname_t + "\"");
            using(StreamReader sr=new StreamReader(xml_fname_t))
            {
                using(FileStream fskun=new FileStream(xml_fname, FileMode.Create))
                {
                    using(StreamWriter sw=new StreamWriter(fskun))
                    {
                        string line;
                        bool isFirstLine = true;
                        while(sr.Peek() >-1)
                        {
                            line = sr.ReadLine();
                            if (isFirstLine)
                            {
                                isFirstLine = false;
                                sw.WriteLine("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>");
                                continue;
                            }
                            sw.WriteLine(line);
                        }
                    }
                }
            }
            System.IO.File.Delete(xml_fname_t);
            IpcServerChannel channel = new IpcServerChannel("neutrino_utau_plugin");
            ChannelServices.RegisterChannel(channel, true);
            settingkun.xml_path = xml_fname;
            settingkun.proj_name = pri.nameD;
            RemotingServices.Marshal(settingkun, "proj_s_data");
            string wrapper_exe = System.AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\') + "\\neutrino_wrapper.exe";
            Process p = new Process();
            p.StartInfo.FileName = wrapper_exe;
            p.StartInfo.Arguments = "connect";
            p.StartInfo.CreateNoWindow = true;
            p.StartInfo.UseShellExecute = false;
            p.StartInfo.RedirectStandardOutput = true;
            p.StartInfo.RedirectStandardError = true;
            p.OutputDataReceived += p_OutputDataReceived;
            p.ErrorDataReceived += p_ErrorDataReceived;
            p.Start();
            p.BeginOutputReadLine();
            p.BeginErrorReadLine();
            p.WaitForExit();
            p.Close();
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
        //OutputDataReceivedイベントハンドラ
        //行が出力されるたびに呼び出される
        static void p_OutputDataReceived(object sender,
            System.Diagnostics.DataReceivedEventArgs e)
        {
            //出力された文字列を表示する
            Console.WriteLine(e.Data);
        }

        //ErrorDataReceivedイベントハンドラ
        static void p_ErrorDataReceived(object sender,
            System.Diagnostics.DataReceivedEventArgs e)
        {
            //エラー出力された文字列を表示する
            Console.Error.WriteLine(e.Data);
        }
        static int run_process(string processname, string args)
        {
            System.Diagnostics.Process p = new System.Diagnostics.Process();
            //出力とエラーをストリームに書き込むようにする
            p.StartInfo.UseShellExecute = false;
            p.StartInfo.RedirectStandardOutput = true;
            p.StartInfo.RedirectStandardError = true;
            p.StartInfo.StandardErrorEncoding = Encoding.UTF8;
            p.StartInfo.StandardOutputEncoding = Encoding.UTF8;

            p.OutputDataReceived += (Object sender, System.Diagnostics.DataReceivedEventArgs e) =>
            {
                Console.WriteLine(e.Data);
            };
            p.ErrorDataReceived += (Object sender, System.Diagnostics.DataReceivedEventArgs e) =>
            {
                Console.Error.WriteLine(e.Data);
            };
            p.StartInfo.FileName = processname;
            p.StartInfo.Arguments = args;
            p.StartInfo.RedirectStandardInput = false;
            p.StartInfo.CreateNoWindow = true;
            p.Start();
            p.BeginOutputReadLine();
            p.BeginErrorReadLine();
            p.WaitForExit();
            int return_v = p.ExitCode;
            p.Close();
            return return_v;
        }
    }
}
