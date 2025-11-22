using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;
using ProyectoBase.GUI.Components;

namespace ProyectoBase.GUI.FormEngine
{
    public static class FormBuilder
    {
        public static UIElement BuildForm(List<FormField> fields)
        {
            var stack = new StackPanel
            {
                Margin = new Thickness(10)
            };

            foreach (var field in fields)
            {
                stack.Children.Add(CreateField(field));
            }

            return stack;
        }

        private static UIElement CreateField(FormField field)
        {
            return field.Type switch
            {
                ""text""        => new TextInput        { Label = field.Label, Value = field.Default ?? "" },
                ""multiline""   => new MultiLineInput  { Label = field.Label, Value = field.Default ?? "" },
                ""number""      => new NumberInput     { Label = field.Label, Value = field.Default ?? "" },
                ""toggle""      => new ToggleSwitch    { Label = field.Label, Value = field.BoolDefault },
                ""combo""       => CreateCombo(field),
                ""slider""      => new SliderInput     { Label = field.Label, Min = field.Min, Max = field.Max, Value = field.DoubleDefault },
                ""section""     => CreateSection(field),
                _ => new TextBlock { Text = $"Tipo desconocido: {field.Type}" }
            };
        }

        private static UIElement CreateCombo(FormField field)
        {
            var combo = new ComboInput { Label = field.Label, Value = field.Default };
            if (field.Items != null)
            {
                foreach (var i in field.Items)
                    combo.Items.Add(i);
            }
            return combo;
        }

        private static UIElement CreateSection(FormField field)
        {
            var section = new GroupedFormSection { Title = field.Label };
            var innerStack = new StackPanel();

            if (field.SubFields != null)
            {
                foreach (var sub in field.SubFields)
                    innerStack.Children.Add(CreateField(sub));
            }

            section.Content = innerStack;
            return section;
        }
    }

    public class FormField
    {
        public string Type { get; set; } = "";
        public string Label { get; set; } = "";
        public string Default { get; set; }
        public bool BoolDefault { get; set; }
        public double DoubleDefault { get; set; }
        public double Min { get; set; }
        public double Max { get; set; }
        public List<string> Items { get; set; }
        public List<FormField> SubFields { get; set; }
    }
}
