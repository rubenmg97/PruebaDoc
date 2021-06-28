using Bussines;
using Entity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace Documentos.Controllers
{
    public class HomeController : Controller
    {
        BusDocumento cmdDoc = new BusDocumento();
        BusKclave cmdClv = new BusKclave();
        BusReporte cmdRep = new BusReporte();

        // GET: Home
        public ActionResult Index()
        {
            return View();
        }

        public JsonResult ObtenerReportes()
        {
            try
            {
                List<EntReporte> lsEmpleado = cmdRep.Obtener();
                return Json(new { mensaje = "ok", ls = lsEmpleado }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                //    List<EntEmpleado> lsUser = new List<EntEmpleado> ();
                return Json(new { mensaje = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }


        public JsonResult ObtenerKclaves(int idDoc)
        {
            try
            {
                List<EntKclave> lsEmpleado = cmdClv.Obtener(idDoc,777);
                return Json(new { mensaje = "ok", ls = lsEmpleado }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                //    List<EntEmpleado> lsUser = new List<EntEmpleado> ();
                return Json(new { mensaje = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }




        public JsonResult ObtenerDocumento(int idDoc)
        {
            try
            {
                EntDocumento empleado = cmdDoc.Obtener(idDoc);
                return Json(new { mensaje = "ok", Ent = empleado }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                return Json(new { mensaje = ex.Message }, JsonRequestBehavior.AllowGet);
            }
        }

        //[HttpPost]
        //public JsonResult Agregar(EntEmpleado e)
        //{
        //    try
        //    {
        //        Comando.Create(e);
        //        return Json(new { mensaje = "ok" }, JsonRequestBehavior.AllowGet);
        //    }
        //    catch (Exception ex)
        //    {
        //        return Json(new { mensaje = ex.Message }, JsonRequestBehavior.AllowGet);
        //    }
        //}

        //public JsonResult BorrarDeServidor(int id)
        //{
        //    try
        //    {
        //        Comando.Delete(id);
        //        return Json(new { mensaje = "ok" }, JsonRequestBehavior.AllowGet);
        //    }
        //    catch (Exception ex)
        //    {
        //        return Json(new { mensaje = ex.Message }, JsonRequestBehavior.AllowGet);
        //    }
        //}

        //[HttpPost]
        //public JsonResult Editar(EntEmpleado e)
        //{
        //    try
        //    {
        //        Comando.Edit(e);
        //        return Json(new { mensaje = "ok" }, JsonRequestBehavior.AllowGet);
        //    }
        //    catch (Exception ex)
        //    {
        //        return Json(new { mensaje = ex.Message }, JsonRequestBehavior.AllowGet);
        //    }
        //}

        //[HttpPost]
        //public JsonResult Buscar(String valor)
        //{
        //    try
        //    {
        //        List<EntEmpleado> lsEmpleado = Comando.Obtener(valor);
        //        return Json(new { mensaje = "ok", ls = lsEmpleado }, JsonRequestBehavior.AllowGet);
        //    }
        //    catch (Exception ex)
        //    {
        //        return Json(new { mensaje = ex.Message }, JsonRequestBehavior.AllowGet);
        //    }
        //}
    }
}