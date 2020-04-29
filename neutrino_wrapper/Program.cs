using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.Remoting.Channels;
using System.Runtime.Remoting.Channels.Ipc;
using System.Text;
using System.Threading.Tasks;
using wrappe_connect;

namespace neutrino_wrapper
{
    class Program
    {
        static void Main(string[] args)
        {
            if (args.Length < 1) return;
            if (!args[0].Equals("connect")) return;
            //クライアントサイドのチャンネルを生成.
            IpcClientChannel channel = new IpcClientChannel();

            //チャンネルを登録
            ChannelServices.RegisterChannel(channel, true);

            wrapper_connect rc = Activator.GetObject(typeof(wrapper_connect), "ipc://neutrino_utau_plugin/proj_s_data") as wrapper_connect;
            wrapper_connect wrc = rc;
            string bindir_name = wrc.neutrino_dirname + "\\bin\\";
            Console.WriteLine(DateTime.Now.ToString("yyyy/MM/dd HH:mm:ss.ff") + " : start MusicXMLtoLabel");
            System.IO.Directory.SetCurrentDirectory(wrc.neutrino_dirname);
            run_process(bindir_name + "musicXMLtoLabel.exe", "\"" + wrc.xml_path + "\"" + " " + "\"" + wrc.neutrino_dirname + "\\score\\label\\full\\" + wrc.proj_name + ".lab\" " + "\"" + wrc.neutrino_dirname + "\\score\\label\\mono\\" + wrc.proj_name + ".lab\"");
            string neutrino_args = "score\\label\\full\\" + wrc.proj_name + ".lab " + "score\\label\\timing\\" + wrc.proj_name + ".lab " +
                "output\\" + wrc.proj_name + ".f0 " + "output\\" + wrc.proj_name + ".mgc"
                + " " + "output\\" + wrc.proj_name + ".bap" +
                " " + "model\\" + wrc.voice + "\\"
                + " -n " + wrc.threads.ToString() + " -t";
            Console.WriteLine(DateTime.Now.ToString("yyyy/MM/dd HH:mm:ss.ff") + " : start NEUTRINO");

            run_process(bindir_name + "NEUTRINO.exe", neutrino_args);
            string WORLD_args = "output\\" + wrc.proj_name + ".f0 output\\" + wrc.proj_name + ".mgc output\\" + wrc.proj_name + ".bap -f " + wrc.PitchShift.ToString() + " -m " + wrc.FormantShift.ToString() + " -o output\\" + wrc.proj_name + "_syn.wav -n " + wrc.threads.ToString() + " -t ";
            Console.WriteLine(DateTime.Now.ToString("yyyy/MM/dd HH:mm:ss.ff") + " : start WORLD");

            run_process(bindir_name + "WORLD.exe", WORLD_args);
            string NSF_IO_args = "score\\label\\full\\" + wrc.proj_name + ".lab " + "score\\label\\timing\\" + wrc.proj_name + ".lab " +
    "output\\" + wrc.proj_name + ".f0 " + "output\\" + wrc.proj_name + ".mgc"
    + " " + "output\\" + wrc.proj_name + ".bap" +
    " " +  wrc.voice + " output\\" + wrc.proj_name + "_nsf.wav" + " -t";
            Console.WriteLine(DateTime.Now.ToString("yyyy/MM/dd HH:mm:ss.ff") + " : start NSF");
            run_process(bindir_name + "NSF_IO.exe", NSF_IO_args);
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
