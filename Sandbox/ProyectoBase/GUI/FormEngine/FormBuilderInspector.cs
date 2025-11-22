using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;

namespace ProyectoBase.GUI.FormEngine
{
    public static class FormBuilderInspector
    {
        public static Dictionary<string,string> ReadFormValues(object content)
        {
            var result = new Dictionary<string,string>();

            if (content is Panel p)
                Traverse(p, result);

            return result;
        }

        private static void Traverse(Panel p, Dictionary<string,string> map)
        {
            foreach (var c in p.Children)
            {
                if (c is Panel sub)
                {
                    Traverse(sub, map);
                    continue;
                }

                if (c is TextBox tb && tb.Tag is FormField tf)
                {
                    var val = tb.Text;
                    if (tf.Validation != null && !tf.Validation(val))
                        throw new Exception($""Valor inválido para '{tf.Label}'"");

                    map[tf.Label] = val;
                }

                if (c is CheckBox cb && cb.Tag is FormField tf2)
                {
                    map[tf2.Label] = cb.IsChecked == true ? ""true"" : ""false"";
                }
            }
        }
    }
}
