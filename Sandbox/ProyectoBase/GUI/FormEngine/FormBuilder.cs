using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows;
using System.Windows.Controls;

namespace ProyectoBase.GUI.FormEngine
{
    public static class FormBuilder
    {
        public static Panel BuildForm(List<FormField> fields)
        {
            var panel = new StackPanel { Margin = new Thickness(0,5,0,5) };

            // Construir campos
            foreach (var f in fields)
            {
                if (f.Type == ""section"")
                {
                    var border = new Border
                    {
                        Margin = new Thickness(0, 10, 0, 10),
                        Padding = new Thickness(10),
                        BorderThickness = new Thickness(1),
                        CornerRadius = new CornerRadius(8),
                        BorderBrush = System.Windows.Media.Brushes.Gray
                    };

                    var subPanel = BuildForm(f.SubFields ?? new List<FormField>());
                    border.Child = subPanel;

                    var title = new TextBlock
                    {
                        Text = f.Label,
                        FontSize = 16,
                        FontWeight = FontWeights.Bold,
                        Margin = new Thickness(0,0,0,6)
                    };

                    var wrapper = new StackPanel();
                    wrapper.Children.Add(title);
                    wrapper.Children.Add(border);

                    panel.Children.Add(wrapper);
                    continue;
                }

                panel.Children.Add(BuildSingle(f));
            }

            // ========== SUBMIT AUTOMÁTICO ==========
            if (fields.Any(f => f.OnSubmit != null))
            {
                var btn = new Button
                {
                    Content = ""Aceptar"",
                    Margin = new Thickness(0,15,0,0),
                    Padding = new Thickness(10),
                };

                btn.Click += (s,e) =>
                {
                    try
                    {
                        var data = FormBuilderInspector.ReadFormValues(panel);

                        foreach (var f in fields)
                            f.OnSubmit?.Invoke(data);
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show(ex.Message, ""Error"", MessageBoxButton.OK);
                    }
                };

                panel.Children.Add(btn);
            }

            return panel;
        }

        private static FrameworkElement BuildSingle(FormField f)
        {
            switch (f.Type)
            {
                case ""text"": return BuildTextField(f);
                case ""number"": return BuildNumberField(f);
                case ""toggle"": return BuildToggleField(f);
                default: return new TextBlock { Text = ""[Tipo no soportado]"" };
            }
        }

        private static FrameworkElement BuildTextField(FormField f)
        {
            var box = new TextBox
            {
                Text = f.Default,
                Margin = new Thickness(0,5,0,5),
                Tag = f
            };

            if (!string.IsNullOrEmpty(f.Placeholder))
                box.Text = f.Placeholder;

            box.TextChanged += (s,e) =>
            {
                ((FormField)box.Tag).OnChange?.Invoke(box.Text);
            };

            return WrapWithLabel(f, box);
        }

        private static FrameworkElement BuildNumberField(FormField f)
        {
            var box = new TextBox
            {
                Text = f.Default,
                Margin = new Thickness(0,5,0,5),
                Tag = f
            };

            box.TextChanged += (s,e) =>
            {
                ((FormField)box.Tag).OnChange?.Invoke(box.Text);
            };

            return WrapWithLabel(f, box);
        }

        private static FrameworkElement BuildToggleField(FormField f)
        {
            var tog = new CheckBox
            {
                IsChecked = f.BoolDefault,
                Margin = new Thickness(0,5,0,5),
                Tag = f
            };

            tog.Checked += (s,e) => ((FormField)tog.Tag).OnChange?.Invoke(""true"");
            tog.Unchecked += (s,e) => ((FormField)tog.Tag).OnChange?.Invoke(""false"");

            return WrapWithLabel(f, tog);
        }

        private static FrameworkElement WrapWithLabel(FormField f, FrameworkElement element)
        {
            var panel = new StackPanel { Margin = new Thickness(0,10,0,10) };

            panel.Children.Add(new TextBlock
            {
                Text = f.Label,
                FontWeight = FontWeights.Bold
            });

            panel.Children.Add(element);

            if (!string.IsNullOrEmpty(f.HelpText))
            {
                panel.Children.Add(new TextBlock
                {
                    Text = f.HelpText,
                    FontSize = 10,
                    Foreground = System.Windows.Media.Brushes.Gray
                });
            }

            return panel;
        }
    }
}
