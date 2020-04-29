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

namespace neutrino_utau_plugin
{
    /// <summary>
    /// ProjectNameInput.xaml の相互作用ロジック
    /// </summary>
    public partial class ProjectNameInput : Window
    {
        public string nameD { get; set; }
        public ProjectNameInput()
        {
            InitializeComponent();
        }

        private void OKButon_Click(object sender, RoutedEventArgs e)
        {
            nameD = FilenameBox.Text;
            this.Close();
        }
    }
}
