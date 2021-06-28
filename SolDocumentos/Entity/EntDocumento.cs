using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Entity
{
    public class EntDocumento
    {
        public int Id { get; set; }
        public String Nombre { get; set; }
        public String Documento { get; set; }
        public int TipoDocumento { get; set; }

        public DateTime Modificacion { get; set; }
        public String Usuario { get; set; }
        public int Estado { get; set; }
    }
}
