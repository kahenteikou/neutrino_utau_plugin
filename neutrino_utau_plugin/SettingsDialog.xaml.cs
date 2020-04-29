using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using Microsoft.WindowsAPICodePack.Dialogs;
using wrappe_connect;
using System.Text.RegularExpressions;
using winform = System.Windows.Forms;

namespace neutrino_utau_plugin
{
    /// <summary>
    /// UserControl1.xaml の相互作用ロジック
    /// </summary>
    public partial class SettingsDialog : Window
    {
        public wrapper_connect wrcon;
        public bool cancel_enable { get; set; }
        public SettingsDialog(wrappe_connect.wrapper_connect wrapper_Connect)
        {
            wrcon = wrapper_Connect;
            cancel_enable = true;
            InitializeComponent();
        }

        private void Neutrino_button_Click(object sender, RoutedEventArgs e)
        {
            CommonOpenFileDialog commonFileDialog = new CommonOpenFileDialog("Neutrinoのフォルダを指定してください。");
            commonFileDialog.IsFolderPicker = true;
            if(commonFileDialog.ShowDialog(this) == CommonFileDialogResult.Ok)
            {
                NEUTRINO_TEXTBOX.Text = commonFileDialog.FileName;
            }
        }

        private void threads_textbox_PreviewTextInput(object sender, TextCompositionEventArgs e)
        {
            e.Handled = !new Regex("[0-9]").IsMatch(e.Text);
        }

        private void threads_textbox_PreviewExecuted(object sender, ExecutedRoutedEventArgs e)
        {
            if (e.Command == ApplicationCommands.Paste)
            {
                e.Handled = true;
            }
        }

        private void OK_Button_Click(object sender, RoutedEventArgs e)
        {
            #region 値が空か確認
            if (this.Formant_textbox.Text.Equals(""))
            {
                winform.MessageBox.Show("Fotmantを指定してください。", "エラー", winform.MessageBoxButtons.OK, winform.MessageBoxIcon.Error);
                return;
            }
            if (this.voice_textbox.Text.Equals(""))
            {
                winform.MessageBox.Show("Voiceを指定してください。", "エラー", winform.MessageBoxButtons.OK, winform.MessageBoxIcon.Error);
                return;
            }
            if (this.Pitch_textbox.Text.Equals(""))
            {
                winform.MessageBox.Show("Pitchを指定してください。", "エラー", winform.MessageBoxButtons.OK, winform.MessageBoxIcon.Error);
                return;
            }
            if (this.NEUTRINO_TEXTBOX.Text.Equals(""))
            {
                winform.MessageBox.Show("Neutrinoのパスを指定してください。", "エラー", winform.MessageBoxButtons.OK, winform.MessageBoxIcon.Error);
                return;
            }
            if (this.threads_textbox.Text.Equals(""))
            {
                winform.MessageBox.Show("threadsを指定してください。", "エラー", winform.MessageBoxButtons.OK, winform.MessageBoxIcon.Error);
                return;
            }
            #endregion
            float pitchkun;
            if (float.TryParse(Pitch_textbox.Text, out pitchkun)){
                wrcon.PitchShift = pitchkun;
            }
            else
            {
                winform.MessageBox.Show("PitchShiftの変換に失敗しました。無効な値が渡された可能性があります。小数のみを指定してください。", "エラー", winform.MessageBoxButtons.OK, winform.MessageBoxIcon.Error);
                return;
            }
            float formantkun;
            if(float.TryParse(Formant_textbox.Text,out formantkun))
            {
                wrcon.FormantShift = formantkun;
            }
            else
            {
                winform.MessageBox.Show("FotmantShiftの変換に失敗しました。無効な値が渡された可能性があります。小数のみを指定してください。", "エラー", winform.MessageBoxButtons.OK, winform.MessageBoxIcon.Error);
                return;
            }
            int threadskun;
            if(int.TryParse(threads_textbox.Text,out threadskun))
            {
                wrcon.threads = threadskun;
            }
            else
            {
                winform.MessageBox.Show("Threadsの変換に失敗しました。無効な値が渡された可能性があります。整数のみを指定してください。", "エラー", winform.MessageBoxButtons.OK, winform.MessageBoxIcon.Error);
                return;
            }
            wrcon.neutrino_dirname = NEUTRINO_TEXTBOX.Text;
            wrcon.voice = voice_textbox.Text;
            this.Close();
            
        }
        private void Cancel_Button_Click(object sender, RoutedEventArgs e)
        {
            this.Close();
        }
        private void Reset_Button_Click(object sender, RoutedEventArgs e)
        {
            this.threads_textbox.Text = "4";
            this.voice_textbox.Text = "KIRITAN";
            this.Pitch_textbox.Text = "1.0";
            this.Formant_textbox.Text = "1.0";
        }

        private void Window_Loaded(object sender, RoutedEventArgs e)
        {
            if (!cancel_enable)
            {
                Cancel_buton.Content = "リセット";
                Cancel_buton.Click += Reset_Button_Click;
            }
            else
            {
                Cancel_buton.Click += Cancel_Button_Click;
            }
        }
    }
}
