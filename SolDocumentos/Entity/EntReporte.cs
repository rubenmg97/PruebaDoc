using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Entity
{
    public class EntReporte
    {
        public int Id { get; set; }
        public String Nombre { get; set; }
        public String Extencion { get; set; }
        public String Ruta { get; set; }
        public String Sprocedure { get; set; }
        public int Parametro { get; set; }
        public String NombreTarea { get; set; }
        public DateTime Fecha { get; set; }

        public int IdDoc { get; set; }
    }
}
