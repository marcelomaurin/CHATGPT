# 📁 توثيق علامة التبويب AI Files

> [!NOTE]
> يحتوي هذا المجلد على مجموعة مكونات لازاروس ضمن علامة التبويب **AI Files**.

## مسح الملفات وإدارة المستندات.
مكونات لمسح المجلدات المحلية وإدارة المستندات المنظمة (المجموعات والمجموعات الفرعية) للفهرسة وRAG.

### مرجع المكونات التفصيلي

| المكون | الوصف | الخصائص الهامة | الأساليب الرئيسية | دور وكيل الذكاء الاصطناعي |
|---|---|---|---|---|
| **TAIDiskTreeScanner** | ماسح شجرة الملفات المحلية. | `TargetFolder, ShowProgress, IncludeSubfolders` | `Scan, StopScan` | مسح المجلدات المحلية وفهرسة الملفات لإعداد مجموعات بيانات الذكاء الاصطناعي. |
| **TAI_DOCFILESMANAGER** | مدير الملفات والمستندات المادية. | `StoragePath, Groups, AutoCreateDirs, AllowOverwrite, MaxGroupNameLength` | `Initialize, AddGrupo, AddSubGrupo, UploadSubGrupo, GetDocument, GetFullDocument` | تنظيم ملفات التوثيق المحلية للاستخدام مع RAG والتدريب. |

### 💻 مثال على كود لازاروس (TAIDiskTreeScanner)

```pascal
var
  MyComponent: TAIDiskTreeScanner;
begin
  MyComponent := TAIDiskTreeScanner.Create(Self);
  try
    // Configuration properties
    // MyComponent.Property := Value;
    
    // Execute call
    // MyComponent.ExecuteMethod;
  finally
    MyComponent.Free;
  end;
end;
```


### ⚡ جسر الذكاء الاصطناعي والأجهزة
يتميز كل مكون من هذه المكونات بخاصية نشر `Prompt` والتي توثق بشكل شفاف واجهتها البرمجية لتوجيه وكلاء الذكاء الاصطناعي (`TAIAgent`) ذاتياً!
