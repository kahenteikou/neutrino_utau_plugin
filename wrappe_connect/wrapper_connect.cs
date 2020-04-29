using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace wrappe_connect
{
    public class wrapper_connect : MarshalByRefObject
    {
        public string neutrino_dirname { get; set; }
        public string xml_path { get; set; }
        public string proj_name { get; set; }
        public int threads { get; set; }
        public string voice { get; set; }
        public float PitchShift { get; set; }
        public float FormantShift { get; set; }
        public bool no_data { get; set; }
        public wrapper_connect()
        {
            neutrino_dirname = "";
            xml_path = "";
            threads = 4;
            voice = "";
            PitchShift = 0;
            FormantShift = 0;
            no_data = true;
            proj_name = "";
        }
    }
}
