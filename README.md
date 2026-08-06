

<p align="center">
  <img src="https://img.shields.io/badge/Delphi-10.3+-red.svg?style=flat-square" alt="Delphi 10.3+">
  <img src="https://img.shields.io/badge/VCL-Win32%2FWin64-blue.svg?style=flat-square" alt="VCL Win32/Win64">
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=flat-square" alt="MIT License">
  <img src="https://img.shields.io/badge/Calendar-Jalali%20(Persian)-orange.svg?style=flat-square" alt="Jalali Calendar">
</p>

<h1 align="center">Jalali DatePicker for Delphi VCL</h1>

<p align="center">
  <b>A professional Persian (Jalali) date picker component for Delphi VCL with full Data-Aware support and advanced UX.</b>
</p>

---

## Table of Contents

- [Key Features](#-key-features)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Properties](#-properties)
- [Events](#-events)
- [Keyboard Shortcuts](#-keyboard-shortcuts)
- [Mouse Interaction](#-mouse-interaction)
- [Date Formats](#-date-formats)
- [Icon Customization](#-icon-customization)
- [Data-Aware Usage](#-data-aware-usage)
- [Safety & Stability](#-safety--stability)
- [Requirements](#-requirements)
- [Preview](#-preview)
- [Contributing](#-contributing)
- [License](#-license)
- [Author](#-author)

---

## ✨ Key Features

- **Full Jalali Calendar** — Accurate Persian year, month, and day calculations
- **Modern UI** — Built-in sleek calendar icon with support for `TImageList` and `TPicture`
- **Mouse-Driven UX** — Click-to-select date parts (Year/Month/Day), Mouse Wheel scrolling
- **Keyboard-Centric** — Edit dates quickly without touching the mouse
- **Data-Aware** — Native `TDataSource` binding with `ftDate` / `ftDateTime` field support
- **Multi-Monitor Aware** — Smart dropdown positioning across multiple displays
- **RTL Support** — Full Right-to-Left alignment support
- **Safe Hooking** — Auto-close dropdown on outside clicks, form move, or resize via secure Windows API subclassing
- **Smart Validation** — Automatic input validation with a dedicated error event

---

## 🚀 Installation

### Manual Install

1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Jalali-DatePicker.git
   ```

2. Add the source folder to your Delphi **Library Path**:
   ```
   Tools > Options > Language > Delphi Options > Library > Library Path
   ```

3. Ensure the following units are available in your project:
   ```delphi
   uses
     Jalali.DatePicker,
     Jalali.Calendar,
     Jalali.CalendarCore;
   ```

4. The component will appear in the **Tool Palette** under the appropriate category.

---

## 📖 Quick Start

### Design-Time
Drop `TJalaliDatePicker` onto your form and configure it via the **Object Inspector**:

```delphi
object JalaliDatePicker1: TJalaliDatePicker
  Left = 24
  Top = 24
  Width = 140
  Height = 24
  DateFormat = jdfYYYYMMDD
  ValueMode = vmJalali
  UseTodayIfEmpty = False
  TabStop = True
end
```

### Run-Time
```delphi
// Set date programmatically
JalaliDatePicker1.Date.Year := 1403;
JalaliDatePicker1.Date.Month := 6;
JalaliDatePicker1.Date.Day := 15;

// Or assign from string
JalaliDatePicker1.Value := '1403/06/15';

// Retrieve as TDateTime (auto-converts to Gregorian)
var
  Dt: TDateTime;
begin
  Dt := JalaliDatePicker1.DateTime;
end;
```

---

## ⚙️ Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Date` | `TJalaliDate` | *Today* | The selected Jalali date |
| `DateTime` | `TDateTime` | `0` | Equivalent Gregorian date/time |
| `Value` | `string` | `''` | Textual date value in the selected format |
| `IsEmpty` | `Boolean` | `True` | Whether the date is empty |
| `DateFormat` | `TJalaliDateFormat` | `jdfYYYYMMDD` | Display format (`YYYY/MM/DD`, `YY/MM/DD`, `YYYY-MM-DD`) |
| `ValueMode` | `TDateValueMode` | `vmJalali` | Output mode: Jalali or Gregorian |
| `UseTodayIfEmpty` | `Boolean` | `False` | Defaults to today's date when empty |
| `SelectedPart` | `TDateSelectPart` | `dspYear` | Currently selected segment (Year/Month/Day) |
| `DropDownWidth` | `Integer` | `0` | Dropdown width (`0` = auto) |
| `Images` | `TCustomImageList` | `nil` | Image list for the drop-down button |
| `ImageIndex` | `TImageIndex` | `-1` | Image index within `Images` |
| `DropIcon` | `TPicture` | `nil` | Custom picture for the drop-down button |
| `ValidationErrorDisplay` | `Boolean` | `True` | Enables validation error handling |
| `DataSource` | `TDataSource` | `nil` | Data source for Data-Aware binding |
| `DataField` | `string` | `''` | Linked field name |

---

## 🎭 Events

| Event | Description |
|-------|-------------|
| `OnChange` | Fires when the user changes the date |
| `OnValidationError` | Fires when invalid text is entered. Provides `InvalidText` and `KeepFocus` parameters. |

### Validation Error Example
```delphi
procedure TForm1.JalaliDatePicker1ValidationError(Sender: TObject;
  const InvalidText: string; var KeepFocus: Boolean);
begin
  ShowMessage('Invalid date entered: ' + InvalidText);
  KeepFocus := True; // Keep focus on the control
end;
```

---

## ⌨️ Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `↑` | Increment the selected part |
| `↓` | Decrement the selected part |
| `←` | Move to previous part (Day → Month → Year) |
| `→` | Move to next part (Year → Month → Day) |
| `Alt + ↓` | Open / Close the dropdown calendar |
| `Tab` | Validate input and move to next control |
| `Backspace` | Clear current part or move to previous part |
| `0-9` | Direct numeric input for the selected part |

---

## 🖱️ Mouse Interaction

| Action | Behavior |
|--------|----------|
| **Click Icon** | Toggle dropdown open/close |
| **Click Year/Month/Day** | Select that segment for editing |
| **Mouse Wheel** | Increment/decrement the active segment |
| **Click Outside** | Automatically close the dropdown |

---

## 📅 Date Formats

```delphi
type
  TJalaliDateFormat = (
    jdfYYYYMMDD,      // 1403/06/15
    jdfYYMMDD,        // 03/06/15
    jdfYYYYMMDD_Dash  // 1403-06-15
  );
```

---

## 🎨 Icon Customization

### Using ImageList
```delphi
JalaliDatePicker1.Images := ImageList1;
JalaliDatePicker1.ImageIndex := 0;
```

### Using TPicture
```delphi
JalaliDatePicker1.DropIcon.LoadFromFile('calendar.png');
```

### Default Icon
If no custom image is assigned, a professional built-in calendar icon is rendered automatically.

---

## 🔗 Data-Aware Usage

```delphi
// Bind to a dataset
JalaliDatePicker1.DataSource := DataSource1;
JalaliDatePicker1.DataField := 'BirthDate'; // ftDate or ftDateTime

// Store as Gregorian in the database while displaying Jalali
JalaliDatePicker1.ValueMode := vmMiladi;
```

---

## 🛡️ Safety & Stability

- **Secure Hooking**: Uses official `SetWindowSubclass` API instead of raw `WindowProc` manipulation
- **Thread-Specific Mouse Hook**: Detects outside clicks without interfering with other application threads
- **Proper Cleanup**: `TFieldDataLink` and dropdown forms are correctly freed in the destructor
- **Multi-Instance Safe**: Multiple pickers can coexist on the same form without conflicts

---

## 📋 Requirements

| Item | Version |
|------|---------|
| Delphi | 10.3 Rio or later |
| Platform | Windows 32-bit / 64-bit (VCL) |
| Dependencies | `Jalali.Calendar`, `Jalali.CalendarCore` |

---

## 🖼️ Preview

> <p align="center">
  <img src="images/Screenshot 2026-08-06 044539.png" alt="Jalali DatePicker Screenshot" width="700">
</p>


## 🤝 Contributing

Contributions are welcome! Please open an [Issue](https://github.com/YOUR_USERNAME/Jalali-DatePicker/issues) to report bugs or request new features.

---

## 📜 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**AF Software**  
📧 AFSoft2010@gmail.com  
🌐 [github.com/faridfhm]([https://github.com/YOUR_USERNAME](https://github.com/faridfhm))

---

<p align="center">
  <b>If you found this project useful, please consider giving it a ⭐!</b>
</p>


