using Data;
using Entity;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Bussines
{
    public class BusReporte
    {
        DatReporte data = new DatReporte();

        public List<EntReporte> Obtener()
        {
            List<EntReporte> ls = new List<EntReporte>();
            DataTable tabla = new DataTable();
            tabla = data.Obtener();
            foreach (DataRow fila in tabla.Rows)
            {
                EntReporte reporte = new EntReporte();
                reporte.Id = Convert.ToInt32(fila["FMT_FL_CVE"]);
                reporte.Nombre = fila["FMT_DS_DESCRIPCION"].ToString();
                reporte.Extencion = fila["FMT_DS_DESCRIPCION"].ToString();
                reporte.Ruta = fila["FMT_DS_DESCRIPCION"].ToString();
                reporte.Sprocedure = fila["FMT_DS_DESCRIPCION"].ToString();
                reporte.Parametro = Convert.ToInt32(fila["FMT_DS_DESCRIPCION"]);
                reporte.NombreTarea = fila["FMT_DS_DESCRIPCION"].ToString();
                reporte.Fecha = Convert.ToDateTime(fila["USU_FE_EGRESO"]);
                reporte.IdDoc = Convert.ToInt32(fila["FMT_FL_CVE"]);
                ls.Add(reporte);
            }
            return ls;
        }

        public EntReporte Obtener(int id)
        {
            DataRow fila = data.Obtener(id);
            EntReporte reporte = new EntReporte();
            reporte.Id = Convert.ToInt32(fila["FMT_FL_CVE"]);
            reporte.Nombre = fila["FMT_DS_DESCRIPCION"].ToString();
            reporte.Extencion = fila["FMT_DS_DESCRIPCION"].ToString();
            reporte.Ruta = fila["FMT_DS_DESCRIPCION"].ToString();
            reporte.Sprocedure = fila["FMT_DS_DESCRIPCION"].ToString();
            reporte.Parametro = Convert.ToInt32(fila["FMT_DS_DESCRIPCION"]);
            reporte.NombreTarea = fila["FMT_DS_DESCRIPCION"].ToString();
            reporte.Fecha = Convert.ToDateTime(fila["USU_FE_EGRESO"]);
            reporte.IdDoc = Convert.ToInt32(fila["FMT_FL_CVE"]);
            return reporte;
        }
    }
}