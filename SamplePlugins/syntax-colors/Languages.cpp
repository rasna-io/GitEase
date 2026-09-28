#include "Languages.h"

#include <QFileInfo>
#include <QHash>

namespace CodeViewer {

namespace {

QSet<QString> words(const char *list, bool lower = false)
{
    QSet<QString> set;
    const QStringList parts = QString::fromLatin1(list).split(QLatin1Char(' '), Qt::SkipEmptyParts);
    for (const QString &word : parts)
        set.insert(lower ? word.toLower() : word);
    return set;
}

QStringList list(const char *items)
{
    return QString::fromLatin1(items).split(QLatin1Char(' '), Qt::SkipEmptyParts);
}

Overlay overlay(const char *pattern, Token token, int group = 0, bool overStrings = false,
                bool overComments = false, bool caseInsensitive = false)
{
    Overlay o;
    o.pattern = QRegularExpression(QString::fromUtf8(pattern),
                                   caseInsensitive ? QRegularExpression::CaseInsensitiveOption
                                                   : QRegularExpression::NoPatternOption);
    o.token = token;
    o.group = group;
    o.overStrings = overStrings;
    o.overComments = overComments;
    return o;
}

Language make(const char *id, const char *name, const char *color, const char *extensions, const char *fileNames = "")
{
    Language l;
    l.id = QString::fromLatin1(id);
    l.name = QString::fromUtf8(name);
    l.color = QColor(QString::fromLatin1(color));
    l.extensions = list(extensions);
    l.fileNames = list(fileNames);
    return l;
}

const Block cBlockComment { QStringLiteral("/*"), QStringLiteral("*/"), Comment };

void cLike(Language &l)
{
    l.lineComments = { QStringLiteral("//") };
    l.blocks = { cBlockComment };
    l.quotes = { QStringLiteral("\""), QStringLiteral("'") };
}

constexpr const char *cKeywords =
    "auto break case const continue default do else enum extern for goto if inline register restrict "
    "return sizeof static struct switch typedef union volatile while _Alignas _Alignof _Atomic _Generic "
    "_Noreturn _Static_assert _Thread_local";
constexpr const char *cTypes =
    "void char short int long float double signed unsigned bool _Bool size_t ssize_t ptrdiff_t intptr_t "
    "uintptr_t int8_t int16_t int32_t int64_t uint8_t uint16_t uint32_t uint64_t wchar_t FILE";
constexpr const char *cppKeywords =
    "alignas alignof and and_eq asm catch class co_await co_return co_yield concept consteval constexpr "
    "constinit const_cast decltype delete dynamic_cast explicit export final friend mutable namespace new "
    "noexcept not not_eq operator or or_eq override private protected public reinterpret_cast requires "
    "static_assert static_cast template this thread_local throw try typeid typename using virtual xor xor_eq "
    "emit signals slots Q_OBJECT Q_PROPERTY Q_INVOKABLE Q_SIGNALS Q_SLOTS Q_EMIT";
constexpr const char *cppTypes =
    "char8_t char16_t char32_t std string string_view vector map unordered_map set unordered_set list deque "
    "array pair tuple optional variant unique_ptr shared_ptr weak_ptr function qint8 qint16 qint32 qint64 "
    "quint8 quint16 quint32 quint64 qreal";
constexpr const char *jsKeywords =
    "async await break case catch class const continue debugger default delete do else export extends "
    "finally for from function get if import in instanceof let new of return set static super switch this "
    "throw try typeof var void while with yield as";
constexpr const char *jsLiterals = "true false null undefined NaN Infinity";
constexpr const char *jsBuiltins =
    "console window document globalThis Math JSON Promise Array Object String Number Boolean Map Set WeakMap "
    "WeakSet Date RegExp Error Symbol BigInt Reflect Proxy Intl parseInt parseFloat isNaN isFinite "
    "setTimeout setInterval clearTimeout clearInterval fetch require module exports process";

QList<Language> buildLanguages()
{
    QList<Language> all;

    // ── Plain text ───────────────────────────────────────────────────────────────────────
    {
        Language l = make("plaintext", "Plain Text", "#8b949e", "txt text log out");
        l.scan = false;
        all << l;
    }

    // ── C family ─────────────────────────────────────────────────────────────────────────
    {
        Language l = make("c", "C", "#a8b9cc", "c");
        cLike(l);
        l.keywords = words(cKeywords);
        l.types = words(cTypes);
        l.literals = words("NULL true false EOF");
        l.builtins = words("printf fprintf sprintf snprintf scanf malloc calloc realloc free memcpy memset strlen strcmp strcpy fopen fclose");
        l.overlays = {
            overlay(R"(^\s*#\s*[A-Za-z_]+)", Annotation),
            overlay(R"(^\s*#\s*include\s*(<[^>]*>))", String, 1),
        };
        all << l;
    }
    {
        Language l = make("cpp", "C++", "#f34b7d", "cpp cc cxx c++ hpp hh hxx h ino inl ipp tpp");
        cLike(l);
        l.keywords = words(cKeywords) + words(cppKeywords);
        l.types = words(cTypes) + words(cppTypes);
        l.literals = words("true false nullptr NULL");
        l.upperTypes = true;
        l.overlays = {
            overlay(R"(^\s*#\s*[A-Za-z_]+)", Annotation),
            overlay(R"(^\s*#\s*include\s*(<[^>]*>))", String, 1),
            overlay(R"(\[\[[^\]]*\]\])", Annotation),
        };
        all << l;
    }
    {
        Language l = make("objc", "Objective-C", "#438eff", "m mm");
        cLike(l);
        l.keywords = words(cKeywords) + words("self super in out inout bycopy byref oneway id instancetype nonatomic atomic strong weak copy assign readonly readwrite");
        l.types = words(cTypes) + words("BOOL NSInteger NSUInteger CGFloat SEL IMP Class");
        l.literals = words("nil Nil YES NO NULL true false");
        l.upperTypes = true;
        l.overlays = {
            overlay(R"(^\s*#\s*[A-Za-z_]+)", Annotation),
            overlay(R"(@[A-Za-z_]+)", Keyword),
        };
        all << l;
    }
    {
        Language l = make("csharp", "C#", "#178600", "cs csx");
        cLike(l);
        l.keywords = words("abstract as async await base break case catch checked class const continue default delegate do else "
                           "enum event explicit extern finally fixed for foreach get goto if implicit in init interface internal is "
                           "lock namespace new operator out override params partial private protected public readonly record ref "
                           "required return sealed set sizeof stackalloc static struct switch this throw try typeof unchecked unsafe "
                           "using value var virtual volatile when where while with yield");
        l.types = words("bool byte sbyte char decimal double float int uint long ulong short ushort object string void dynamic nint nuint");
        l.literals = words("true false null");
        l.upperTypes = true;
        l.overlays = {
            overlay(R"(^\s*#\s*[A-Za-z_]+)", Annotation),
            overlay(R"(^\s*\[[A-Za-z_][\w.]*)", Annotation),
        };
        all << l;
    }
    {
        Language l = make("java", "Java", "#b07219", "java");
        cLike(l);
        l.keywords = words("abstract assert break case catch class const continue default do else enum exports extends final "
                           "finally for goto if implements import instanceof interface module native new non-sealed package permits "
                           "private protected public record requires return sealed static strictfp super switch synchronized this "
                           "throw throws transient try var void volatile while yield");
        l.types = words("boolean byte char short int long float double String Object Integer Long Double Boolean List Map Set Optional");
        l.literals = words("true false null");
        l.upperTypes = true;
        l.overlays = { overlay(R"(@[A-Za-z_][\w.]*)", Annotation) };
        all << l;
    }
    {
        Language l = make("kotlin", "Kotlin", "#a97bff", "kt kts");
        cLike(l);
        l.blocks = { cBlockComment, Block { QStringLiteral("\"\"\""), QStringLiteral("\"\"\""), String } };
        l.keywords = words("abstract actual annotation as break by catch class companion const constructor continue crossinline "
                           "data do else enum expect external final finally for fun get if import in infix init inline inner "
                           "interface internal is lateinit noinline object open operator out override package private protected "
                           "public reified return sealed set super suspend tailrec this throw try typealias val var vararg when "
                           "where while");
        l.types = words("Int Long Short Byte Double Float Boolean Char String Unit Any Nothing List Map Set Array");
        l.literals = words("true false null");
        l.upperTypes = true;
        l.overlays = {
            overlay(R"(@[A-Za-z_][\w.]*)", Annotation),
            overlay(R"(\$\{[^}]*\}|\$[A-Za-z_]\w*)", Variable, 0, true),
        };
        all << l;
    }
    {
        Language l = make("swift", "Swift", "#f05138", "swift");
        cLike(l);
        l.blocks = { cBlockComment, Block { QStringLiteral("\"\"\""), QStringLiteral("\"\"\""), String, true } };
        l.keywords = words("associatedtype async await break case catch class continue default defer deinit do else enum extension "
                           "fallthrough fileprivate final for func guard if import in indirect init inout internal is lazy let "
                           "mutating nonmutating open operator override private protocol public repeat required rethrows return "
                           "some any static struct subscript super switch throw throws try typealias var weak where while");
        l.types = words("Int Double Float Bool String Character Array Dictionary Set Optional Void Any AnyObject Self");
        l.literals = words("true false nil self");
        l.upperTypes = true;
        l.overlays = {
            overlay(R"(@[A-Za-z_]\w*)", Annotation),
            overlay(R"(#[A-Za-z_]\w*)", Annotation),
            overlay(R"(\\\([^)]*\))", Variable, 0, true),
        };
        all << l;
    }
    {
        Language l = make("go", "Go", "#00add8", "go", "go.mod go.sum");
        cLike(l);
        l.quotes = { QStringLiteral("\""), QStringLiteral("'") };
        l.blocks = { cBlockComment, Block { QStringLiteral("`"), QStringLiteral("`"), String } };
        l.keywords = words("break case chan const continue default defer else fallthrough for func go goto if import interface "
                           "map package range return select struct switch type var");
        l.types = words("bool byte complex64 complex128 error float32 float64 int int8 int16 int32 int64 rune string uint uint8 "
                        "uint16 uint32 uint64 uintptr any comparable");
        l.literals = words("true false nil iota");
        l.builtins = words("append cap clear close complex copy delete imag len make max min new panic print println real recover");
        all << l;
    }
    {
        Language l = make("rust", "Rust", "#dea584", "rs");
        cLike(l);
        l.quotes = { QStringLiteral("\"") };
        l.keywords = words("as async await break const continue crate dyn else enum extern fn for if impl in let loop match mod "
                           "move mut pub ref return self Self static struct super trait type union unsafe use where while");
        l.types = words("bool char str i8 i16 i32 i64 i128 isize u8 u16 u32 u64 u128 usize f32 f64 String Vec Option Result Box "
                        "Rc Arc HashMap HashSet");
        l.literals = words("true false None Some Ok Err");
        l.upperTypes = true;
        l.overlays = {
            overlay(R"('[A-Za-z_]\w*\b(?!'))", Variable),
            overlay(R"('(\\.|[^\\'])')", String),
            overlay(R"(\b[a-z_]\w*!)", Builtin),
            overlay(R"(#!?\[[^\]]*\])", Annotation),
        };
        all << l;
    }
    {
        Language l = make("zig", "Zig", "#ec915c", "zig zon");
        l.lineComments = { QStringLiteral("//") };
        l.quotes = { QStringLiteral("\""), QStringLiteral("'") };
        l.keywords = words("addrspace align allowzero and anyframe anytype asm async await break callconv catch comptime const "
                           "continue defer else enum errdefer error export extern fn for if inline linksection noalias noinline "
                           "nosuspend opaque or orelse packed pub resume return struct suspend switch test threadlocal try union "
                           "unreachable usingnamespace var volatile while");
        l.types = words("i8 i16 i32 i64 i128 u8 u16 u32 u64 u128 isize usize f16 f32 f64 f128 bool void type anyerror noreturn");
        l.literals = words("true false null undefined");
        l.upperTypes = true;
        l.overlays = { overlay(R"(@[A-Za-z_]\w*)", Builtin) };
        all << l;
    }
    {
        Language l = make("dart", "Dart", "#00b4ab", "dart");
        cLike(l);
        l.blocks = { cBlockComment,
                     Block { QStringLiteral("'''"), QStringLiteral("'''"), String, true },
                     Block { QStringLiteral("\"\"\""), QStringLiteral("\"\"\""), String, true } };
        l.keywords = words("abstract as assert async await base break case catch class const continue covariant default deferred "
                           "do dynamic else enum export extends extension external factory final finally for get hide if implements "
                           "import in interface is late library mixin new on operator part required rethrow return sealed set show "
                           "static super switch sync this throw try typedef var void when while with yield");
        l.types = words("int double num bool String List Map Set Future Stream Object Never Iterable");
        l.literals = words("true false null");
        l.upperTypes = true;
        l.overlays = {
            overlay(R"(@[A-Za-z_]\w*)", Annotation),
            overlay(R"(\$\{[^}]*\}|\$[A-Za-z_]\w*)", Variable, 0, true),
        };
        all << l;
    }
    {
        Language l = make("scala", "Scala", "#c22d40", "scala sc sbt");
        cLike(l);
        l.blocks = { cBlockComment, Block { QStringLiteral("\"\"\""), QStringLiteral("\"\"\""), String } };
        l.keywords = words("abstract case catch class def do else enum export extends final finally for forSome given if implicit "
                           "import lazy match new object override package private protected return sealed super then this throw "
                           "trait try type using val var while with yield");
        l.types = words("Int Long Double Float Boolean Char String Unit Any AnyRef Nothing Option List Map Seq Vector");
        l.literals = words("true false null None Some");
        l.upperTypes = true;
        l.overlays = { overlay(R"(@[A-Za-z_]\w*)", Annotation) };
        all << l;
    }
    {
        Language l = make("groovy", "Groovy", "#4298b8", "groovy gradle gvy", "Jenkinsfile");
        cLike(l);
        l.blocks = { cBlockComment,
                     Block { QStringLiteral("'''"), QStringLiteral("'''"), String, true },
                     Block { QStringLiteral("\"\"\""), QStringLiteral("\"\"\""), String, true } };
        l.keywords = words("as assert break case catch class const continue def default do else enum extends final finally for "
                           "goto if implements import in instanceof interface new package return static super switch this throw "
                           "throws trait try var while");
        l.types = words("int long double float boolean char byte short void String Object List Map");
        l.literals = words("true false null");
        l.upperTypes = true;
        l.overlays = { overlay(R"(@[A-Za-z_]\w*)", Annotation), overlay(R"(\$\{[^}]*\})", Variable, 0, true) };
        all << l;
    }

    // ── Web ──────────────────────────────────────────────────────────────────────────────
    {
        Language l = make("javascript", "JavaScript", "#f1e05a", "js mjs cjs jsx");
        cLike(l);
        l.blocks = { cBlockComment, Block { QStringLiteral("`"), QStringLiteral("`"), String, true } };
        l.keywords = words(jsKeywords);
        l.literals = words(jsLiterals);
        l.builtins = words(jsBuiltins);
        l.identExtra = QStringLiteral("$");
        l.upperTypes = true;
        l.overlays = {
            overlay(R"(@[A-Za-z_]\w*)", Annotation),
            overlay(R"(\$\{[^}]*\})", Variable, 0, true),
        };
        all << l;
    }
    {
        Language l = make("typescript", "TypeScript", "#3178c6", "ts tsx mts cts");
        cLike(l);
        l.blocks = { cBlockComment, Block { QStringLiteral("`"), QStringLiteral("`"), String, true } };
        l.keywords = words(jsKeywords) + words("abstract declare enum implements interface keyof namespace private protected public "
                                               "readonly satisfies type infer is asserts override accessor");
        l.types = words("string number boolean any unknown never void object symbol bigint Record Partial Readonly Pick Omit Array Promise");
        l.literals = words(jsLiterals);
        l.builtins = words(jsBuiltins);
        l.identExtra = QStringLiteral("$");
        l.upperTypes = true;
        l.overlays = {
            overlay(R"(@[A-Za-z_]\w*)", Annotation),
            overlay(R"(\$\{[^}]*\})", Variable, 0, true),
        };
        all << l;
    }
    {
        Language l = make("qml", "QML", "#44a51c", "qml qmlproject", "qmldir");
        cLike(l);
        l.blocks = { cBlockComment, Block { QStringLiteral("`"), QStringLiteral("`"), String, true } };
        l.keywords = words(jsKeywords) + words("property signal readonly required default alias pragma component enum");
        l.types = words("int real double bool string var url color list date point rect size font");
        l.literals = words(jsLiterals);
        l.builtins = words("Qt console Math JSON parent root");
        l.upperTypes = true;
        l.overlays = {
            overlay(R"(\b[a-z][\w.]*(?=\s*:(?!:)))", Property),
            overlay(R"(\bon[A-Z]\w*)", Annotation),
        };
        all << l;
    }
    {
        Language l = make("html", "HTML", "#e34c26", "html htm xhtml vue svelte astro");
        l.blocks = { Block { QStringLiteral("<!--"), QStringLiteral("-->"), Comment } };
        l.identExtra = QStringLiteral("-:");
        l.functions = false;
        l.members = false;
        l.numbers = false;
        l.operators = false;
        l.brackets = false;
        l.overlays = {
            overlay(R"(</?\s*([A-Za-z][\w:.-]*))", Tag, 1),
            overlay(R"(</?|/?>)", Punctuation),
            overlay(R"(\s([A-Za-z_:@#.][\w:.-]*)(?=\s*=))", Attribute, 1),
            overlay(R"(=\s*("[^"]*"|'[^']*'))", String, 1),
            overlay(R"(&[#\w]+;)", Constant),
            overlay(R"(<!DOCTYPE[^>]*>)", Annotation, 0, false, false, true),
        };
        all << l;
    }
    {
        Language l = make("xml", "XML", "#0060ac", "xml svg xsd xsl xslt ui qrc csproj vcxproj vbproj fsproj props targets plist resx xaml wsdl rss atom nuspec");
        l.blocks = { Block { QStringLiteral("<!--"), QStringLiteral("-->"), Comment },
                     Block { QStringLiteral("<![CDATA["), QStringLiteral("]]>"), String } };
        l.identExtra = QStringLiteral("-:");
        l.functions = false;
        l.members = false;
        l.numbers = false;
        l.operators = false;
        l.brackets = false;
        l.overlays = {
            overlay(R"(</?\s*([A-Za-z_][\w:.-]*))", Tag, 1),
            overlay(R"(</?|/?>|<\?|\?>)", Punctuation),
            overlay(R"(\s([A-Za-z_:][\w:.-]*)(?=\s*=))", Attribute, 1),
            overlay(R"(=\s*("[^"]*"|'[^']*'))", String, 1),
            overlay(R"(&[#\w]+;)", Constant),
            overlay(R"(<\?xml[^?]*\?>)", Annotation),
        };
        all << l;
    }
    auto cssCommon = [](Language &l) {
        l.blocks = { cBlockComment };
        l.quotes = { QStringLiteral("\""), QStringLiteral("'") };
        l.identExtra = QStringLiteral("-");
        l.members = false;
        l.literals = words("none auto inherit initial unset revert transparent currentColor block inline flex grid absolute "
                           "relative fixed sticky solid dashed dotted bold normal italic center left right top bottom");
        l.overlays = {
            overlay(R"((?<![\w-])[.#][A-Za-z_-][\w-]*(?=[^;{}]*\{))", Type),
            overlay(R"((?:^|[{;])\s*([A-Za-z-]+)\s*:(?!:)[^{]*$)", Property, 1),
            overlay(R"(#[0-9a-fA-F]{3,8}\b)", Constant),
            overlay(R"(@[\w-]+)", Keyword),
            overlay(R"(::?[a-z-]+(?=[^;{}]*\{))", Keyword),
            overlay(R"(--[\w-]+)", Variable),
            overlay(R"(!important)", Keyword),
        };
    };
    {
        Language l = make("css", "CSS", "#663399", "css");
        cssCommon(l);
        all << l;
    }
    {
        Language l = make("scss", "SCSS", "#c6538c", "scss sass");
        cssCommon(l);
        l.lineComments = { QStringLiteral("//") };
        l.overlays << overlay(R"(\$[\w-]+)", Variable) << overlay(R"(#\{[^}]*\})", Variable, 0, true);
        all << l;
    }
    {
        Language l = make("less", "Less", "#2a4d8f", "less");
        cssCommon(l);
        l.lineComments = { QStringLiteral("//") };
        l.overlays << overlay(R"(@[\w-]+(?=\s*:))", Variable);
        all << l;
    }
    {
        Language l = make("json", "JSON", "#cbcb41", "json jsonc json5 geojson webmanifest code-workspace", ".babelrc .eslintrc .prettierrc");
        l.lineComments = { QStringLiteral("//") };
        l.blocks = { cBlockComment };
        l.quotes = { QStringLiteral("\"") };
        l.literals = words("true false null");
        l.functions = false;
        l.members = false;
        l.overlays = { overlay(R"(("(?:[^"\\]|\\.)*")\s*:)", Property, 1, true) };
        all << l;
    }
    {
        Language l = make("graphql", "GraphQL", "#e10098", "graphql gql graphqls");
        l.lineComments = { QStringLiteral("#") };
        l.blocks = { Block { QStringLiteral("\"\"\""), QStringLiteral("\"\"\""), String } };
        l.quotes = { QStringLiteral("\"") };
        l.keywords = words("query mutation subscription fragment on type interface union enum input scalar schema extend implements directive repeatable");
        l.types = words("Int Float String Boolean ID");
        l.literals = words("true false null");
        l.upperTypes = true;
        l.overlays = { overlay(R"(\$\w+)", Variable), overlay(R"(@\w+)", Annotation) };
        all << l;
    }

    // ── Scripting ────────────────────────────────────────────────────────────────────────
    {
        Language l = make("python", "Python", "#3572a5", "py pyw pyi pyx", "SConstruct SConscript");
        l.lineComments = { QStringLiteral("#") };
        l.blocks = { Block { QStringLiteral("\"\"\""), QStringLiteral("\"\"\""), String, true },
                     Block { QStringLiteral("'''"), QStringLiteral("'''"), String, true } };
        l.quotes = { QStringLiteral("\""), QStringLiteral("'") };
        l.keywords = words("and as assert async await break class continue def del elif else except finally for from global if "
                           "import in is lambda nonlocal not or pass raise return try while with yield match case type");
        l.literals = words("True False None Ellipsis NotImplemented");
        l.builtins = words("print len range dict list set tuple str int float bool bytes open super isinstance issubclass enumerate "
                           "zip map filter sorted reversed min max sum abs any all type object self cls iter next repr hash id "
                           "getattr setattr hasattr format input round divmod");
        l.types = words("Exception ValueError TypeError KeyError IndexError RuntimeError");
        l.upperTypes = true;
        l.overlays = {
            overlay(R"(^\s*@[\w.]+)", Annotation),
            overlay(R"(\b__\w+__\b)", Builtin),
            overlay(R"(\{[^{}"']*\})", Variable, 0, true),
        };
        all << l;
    }
    {
        Language l = make("ruby", "Ruby", "#cc342d", "rb rake gemspec ru erb", "Gemfile Rakefile Guardfile Podfile Vagrantfile");
        l.lineComments = { QStringLiteral("#") };
        l.blocks = { Block { QStringLiteral("=begin"), QStringLiteral("=end"), Comment, false, true } };
        l.quotes = { QStringLiteral("\""), QStringLiteral("'") };
        l.keywords = words("alias and begin break case class def defined? do else elsif end ensure for if in module next not or "
                           "redo rescue retry return super then undef unless until when while yield require require_relative "
                           "attr_reader attr_writer attr_accessor private protected public include extend");
        l.literals = words("true false nil self __FILE__ __LINE__");
        l.builtins = words("puts print p pp raise lambda proc loop");
        l.identExtra = QStringLiteral("?!");
        l.upperTypes = true;
        l.overlays = {
            overlay(R"((?<![\w:]):[A-Za-z_]\w*[?!]?)", Constant),
            overlay(R"(@{1,2}[A-Za-z_]\w*|\$[A-Za-z_]\w*)", Variable),
            overlay(R"(#\{[^}]*\})", Variable, 0, true),
        };
        all << l;
    }
    {
        Language l = make("php", "PHP", "#4f5d95", "php phtml php3 php4 php5 phps");
        l.lineComments = { QStringLiteral("//"), QStringLiteral("#") };
        l.blocks = { cBlockComment };
        l.quotes = { QStringLiteral("\""), QStringLiteral("'") };
        l.keywords = words("abstract and array as break callable case catch class clone const continue declare default do echo "
                           "else elseif empty enddeclare endfor endforeach endif endswitch endwhile enum extends final finally fn "
                           "for foreach function global goto if implements include include_once instanceof insteadof interface "
                           "isset list match namespace new or print private protected public readonly require require_once return "
                           "static switch throw trait try unset use var while xor yield", true);
        l.types = words("int float string bool array object mixed void never iterable callable self parent static");
        l.literals = words("true false null TRUE FALSE NULL");
        l.caseInsensitive = true;
        l.upperTypes = true;
        l.overlays = {
            overlay(R"(\$[A-Za-z_]\w*)", Variable, 0, true),
            overlay(R"(<\?php|<\?=|\?>)", Annotation),
            overlay(R"(#\[[^\]]*\])", Annotation),
        };
        all << l;
    }
    {
        Language l = make("perl", "Perl", "#0298c3", "pl pm pod t psgi");
        l.lineComments = { QStringLiteral("#") };
        l.blocks = { Block { QStringLiteral("=pod"), QStringLiteral("=cut"), Comment, false, true },
                     Block { QStringLiteral("=head1"), QStringLiteral("=cut"), Comment, false, true } };
        l.quotes = { QStringLiteral("\""), QStringLiteral("'") };
        l.keywords = words("my our local sub return if elsif else unless while until for foreach last next redo do use no require "
                           "package BEGIN END eq ne lt gt le ge cmp and or not x");
        l.builtins = words("print printf say die warn open close push pop shift unshift split join map grep sort keys values exists defined scalar");
        l.overlays = { overlay(R"([$@%][A-Za-z_]\w*|\$\{[^}]*\})", Variable, 0, true) };
        all << l;
    }
    {
        Language l = make("lua", "Lua", "#5d6cf0", "lua luau rockspec");
        l.blocks = { Block { QStringLiteral("--[["), QStringLiteral("]]"), Comment },
                     Block { QStringLiteral("[["), QStringLiteral("]]"), String } };
        l.lineComments = { QStringLiteral("--") };
        l.quotes = { QStringLiteral("\""), QStringLiteral("'") };
        l.keywords = words("and break do else elseif end for function goto if in local not or repeat return then until while");
        l.literals = words("true false nil");
        l.builtins = words("print pairs ipairs type tostring tonumber require select error assert pcall xpcall setmetatable "
                           "getmetatable table string math os io coroutine");
        all << l;
    }
    {
        Language l = make("r", "R", "#198ce7", "r rmd");
        l.lineComments = { QStringLiteral("#") };
        l.quotes = { QStringLiteral("\""), QStringLiteral("'") };
        l.keywords = words("if else repeat while function for in next break return library require");
        l.literals = words("TRUE FALSE NULL NA NaN Inf NA_integer_ NA_real_ NA_character_");
        l.builtins = words("c list data.frame vector matrix print cat paste paste0 sum mean median length nrow ncol apply sapply lapply");
        l.identExtra = QStringLiteral(".");
        l.members = false;
        l.overlays = { overlay(R"(<<?-|->>?)", Operator) };
        all << l;
    }
    {
        Language l = make("julia", "Julia", "#a270ba", "jl");
        l.lineComments = { QStringLiteral("#") };
        l.blocks = { Block { QStringLiteral("#="), QStringLiteral("=#"), Comment },
                     Block { QStringLiteral("\"\"\""), QStringLiteral("\"\"\""), String, true } };
        l.quotes = { QStringLiteral("\"") };
        l.keywords = words("abstract baremodule begin break catch const continue do else elseif end export finally for function "
                           "global if import let local macro module mutable primitive quote return struct try type using while where");
        l.types = words("Int Int8 Int16 Int32 Int64 UInt8 Float32 Float64 Bool String Char Vector Matrix Array Dict Nothing Any");
        l.literals = words("true false nothing missing NaN Inf");
        l.identExtra = QStringLiteral("!");
        l.upperTypes = true;
        l.overlays = { overlay(R"(@[A-Za-z_]\w*)", Annotation), overlay(R"(\$\w+|\$\([^)]*\))", Variable, 0, true) };
        all << l;
    }
    {
        Language l = make("haskell", "Haskell", "#5e5086", "hs lhs");
        l.lineComments = { QStringLiteral("--") };
        l.blocks = { Block { QStringLiteral("{-"), QStringLiteral("-}"), Comment } };
        l.quotes = { QStringLiteral("\"") };
        l.keywords = words("case class data default deriving do else foreign if import in infix infixl infixr instance let module "
                           "newtype of then type where qualified as hiding forall");
        l.literals = words("True False Nothing Just Left Right");
        l.identExtra = QStringLiteral("'");
        l.upperTypes = true;
        l.functions = false;
        l.members = false;
        all << l;
    }
    {
        Language l = make("elixir", "Elixir", "#6e4a7e", "ex exs heex", "mix.lock");
        l.lineComments = { QStringLiteral("#") };
        l.blocks = { Block { QStringLiteral("\"\"\""), QStringLiteral("\"\"\""), String, true } };
        l.quotes = { QStringLiteral("\""), QStringLiteral("'") };
        l.keywords = words("def defp defmodule defstruct defmacro defimpl defprotocol do end fn if else unless case cond when with "
                           "for receive try catch rescue after raise import alias require use quote unquote in and or not");
        l.literals = words("true false nil");
        l.identExtra = QStringLiteral("?!");
        l.upperTypes = true;
        l.overlays = {
            overlay(R"((?<![\w:]):[A-Za-z_]\w*[?!]?)", Constant),
            overlay(R"(@[A-Za-z_]\w*)", Annotation),
            overlay(R"(#\{[^}]*\})", Variable, 0, true),
        };
        all << l;
    }
    {
        Language l = make("clojure", "Clojure / Lisp", "#db5855", "clj cljs cljc edn lisp lsp el scm ss rkt fnl");
        l.lineComments = { QStringLiteral(";") };
        l.quotes = { QStringLiteral("\"") };
        l.keywords = words("def defn defn- defmacro defrecord defprotocol defmulti defmethod fn let letfn if if-not when when-not "
                           "cond case do loop recur ns require import quote try catch finally throw and or not define lambda setq defun");
        l.literals = words("true false nil t");
        l.identExtra = QStringLiteral("-?!*+<>=/.");
        l.functions = false;
        l.members = false;
        l.overlays = {
            overlay(R"((?<=\()\s*([A-Za-z_*+!?<>=/.-][\w*+!?<>=/.-]*))", Function, 1),
            overlay(R"((?<![\w-]):[\w.-]+)", Constant),
        };
        all << l;
    }

    // ── Shells ───────────────────────────────────────────────────────────────────────────
    {
        Language l = make("shell", "Shell", "#89e051", "sh bash zsh fish ksh command",
                          ".bashrc .bash_profile .bash_aliases .zshrc .zprofile .profile PKGBUILD");
        l.lineComments = { QStringLiteral("#") };
        l.commentNeedsSpace = true;
        l.quotes = { QStringLiteral("\""), QStringLiteral("'"), QStringLiteral("`") };
        l.keywords = words("if then else elif fi for while until do done case esac in function select return exit break continue "
                           "local export readonly declare typeset unset shift trap source alias");
        l.builtins = words("echo printf cd pwd ls cat grep sed awk cut sort uniq head tail find xargs test read set eval exec sudo "
                           "git mkdir rm cp mv chmod chown curl wget tar");
        l.literals = words("true false");
        l.identExtra = QStringLiteral("-");
        l.members = false;
        l.overlays = {
            overlay(R"(\$\{[^}]*\}|\$\([^)]*\)|\$[A-Za-z_@#?*!$0-9]\w*)", Variable, 0, true),
            overlay(R"((?<=\s)--?[A-Za-z][\w-]*)", Attribute),
            overlay(R"(^#!.*)", Annotation, 0, false, true),
        };
        all << l;
    }
    {
        Language l = make("powershell", "PowerShell", "#3a7bd5", "ps1 psm1 psd1");
        l.lineComments = { QStringLiteral("#") };
        l.blocks = { Block { QStringLiteral("<#"), QStringLiteral("#>"), Comment } };
        l.quotes = { QStringLiteral("\""), QStringLiteral("'") };
        l.stringEscapes = false;
        l.caseInsensitive = true;
        l.keywords = words("begin break catch class continue data default do dynamicparam else elseif end enum exit filter finally "
                           "for foreach from function if in param process return switch throw trap try until using while", true);
        l.literals = words("$true $false $null", true);
        l.identExtra = QStringLiteral("-");
        l.members = true;
        l.overlays = {
            overlay(R"(\b[A-Za-z]+-[A-Za-z]+\b)", Function),
            overlay(R"(\$[\w:]+|\$\{[^}]*\})", Variable, 0, true),
            overlay(R"((?<=\s)-[A-Za-z]\w*)", Attribute),
            overlay(R"(\[[A-Za-z][\w.]*\])", Type),
        };
        all << l;
    }
    {
        Language l = make("batch", "Batch", "#c1f12e", "bat cmd");
        l.quotes = { QStringLiteral("\"") };
        l.stringEscapes = false;
        l.caseInsensitive = true;
        l.keywords = words("echo set if else for in do goto call exit not exist defined errorlevel setlocal endlocal pause cd "
                           "pushd popd shift start copy del move mkdir rmdir type title cls equ neq lss leq gtr geq", true);
        l.literals = words("on off nul", true);
        l.functions = false;
        l.members = false;
        l.overlays = {
            overlay(R"(%[\w~:]+%|%%?~?\w|![\w]+!)", Variable, 0, true),
            overlay(R"(^\s*:[A-Za-z_]\w*)", Function),
            overlay(R"(^\s*@)", Punctuation),
            overlay(R"(^\s*(rem\b|::).*$)", Comment, 0, true, true, true),
        };
        all << l;
    }

    // ── Data and query ───────────────────────────────────────────────────────────────────
    {
        Language l = make("sql", "SQL", "#e38c00", "sql psql mysql pgsql ddl dml");
        l.lineComments = { QStringLiteral("--") };
        l.blocks = { cBlockComment };
        l.quotes = { QStringLiteral("'"), QStringLiteral("\"") };
        l.stringEscapes = false;
        l.caseInsensitive = true;
        l.keywords = words("select from where and or not in is like between join inner left right full outer cross on as group by "
                           "order having limit offset union all distinct insert into values update set delete create alter drop "
                           "table view index unique primary key foreign references default constraint check if exists begin commit "
                           "rollback transaction case when then else end with recursive returning desc asc over partition window", true);
        l.types = words("int integer bigint smallint serial decimal numeric real float double boolean bool char varchar text date "
                        "time timestamp timestamptz interval json jsonb uuid blob bytea", true);
        l.literals = words("null true false", true);
        l.builtins = words("count sum avg min max now coalesce nullif cast lower upper length substring trim round row_number rank", true);
        l.functions = false;
        all << l;
    }
    {
        Language l = make("protobuf", "Protocol Buffers", "#6a9fb5", "proto");
        cLike(l);
        l.keywords = words("syntax edition package import option message enum service rpc returns stream oneof map reserved "
                           "extensions extend repeated optional required to max");
        l.types = words("double float int32 int64 uint32 uint64 sint32 sint64 fixed32 fixed64 sfixed32 sfixed64 bool string bytes");
        l.literals = words("true false");
        l.upperTypes = true;
        all << l;
    }
    {
        Language l = make("yaml", "YAML", "#cb171e", "yml yaml", ".clang-format .clang-tidy .gitlab-ci.yml");
        l.lineComments = { QStringLiteral("#") };
        l.commentNeedsSpace = true;
        l.quotes = { QStringLiteral("\""), QStringLiteral("'") };
        l.literals = words("true false null yes no on off True False Null Yes No On Off ~");
        l.functions = false;
        l.members = false;
        l.brackets = true;
        l.overlays = {
            overlay(R"(^(\s*-?\s*)([\w.\-/ ]+?|"[^"]*"|'[^']*')(?=\s*:(\s|$)))", Property, 2, true),
            overlay(R"([&*][\w-]+)", Variable),
            overlay(R"(^(---|\.\.\.)\s*$)", Annotation),
            overlay(R"(^\s*-(?=\s))", Punctuation),
            overlay(R"(!!?[\w/]+)", Type),
            overlay(R"(\$\{\{[^}]*\}\})", Variable, 0, true),
        };
        all << l;
    }
    {
        Language l = make("toml", "TOML", "#9c4221", "toml", "Cargo.lock Pipfile poetry.lock");
        l.lineComments = { QStringLiteral("#") };
        l.blocks = { Block { QStringLiteral("\"\"\""), QStringLiteral("\"\"\""), String, true },
                     Block { QStringLiteral("'''"), QStringLiteral("'''"), String } };
        l.quotes = { QStringLiteral("\""), QStringLiteral("'") };
        l.literals = words("true false inf nan");
        l.functions = false;
        l.members = false;
        l.overlays = {
            overlay(R"(^\s*\[\[?[^\]]+\]\]?)", Type),
            overlay(R"(^\s*([\w.\-"']+)\s*=)", Property, 1, true),
            overlay(R"(\b\d{4}-\d{2}-\d{2}([T ]\d{2}:\d{2}(:\d{2})?)?)", Constant),
        };
        all << l;
    }
    {
        Language l = make("ini", "INI / Config", "#d1dbe0", "ini cfg conf cnf properties env editorconfig gitconfig inf reg desktop service",
                          ".gitignore .gitattributes .gitmodules .editorconfig .env .npmrc .dockerignore .hgignore .gitconfig");
        l.lineComments = { QStringLiteral(";"), QStringLiteral("#") };
        l.quotes = { QStringLiteral("\"") };
        l.literals = words("true false yes no on off");
        l.functions = false;
        l.members = false;
        l.brackets = false;
        l.overlays = {
            overlay(R"(^\s*\[[^\]]+\])", Type),
            overlay(R"(^\s*([^=:\s#;][^=:]*?)\s*[=:])", Property, 1),
            overlay(R"(^\s*!.*)", Operator),
        };
        all << l;
    }
    {
        Language l = make("markdown", "Markdown", "#519aba", "md markdown mdx mkd rst", "README LICENSE CHANGELOG");
        l.blocks = { Block { QStringLiteral("```"), QStringLiteral("```"), Code, false, true },
                     Block { QStringLiteral("<!--"), QStringLiteral("-->"), Comment } };
        l.functions = false;
        l.members = false;
        l.numbers = false;
        l.operators = false;
        l.brackets = false;
        l.overlays = {
            overlay(R"(^#{1,6}\s.*$)", Heading),
            overlay(R"((\*\*|__)(?=\S)(.+?)(?<=\S)\1)", Keyword),
            overlay(R"((?<![*\w])\*(?=\S)[^*]+(?<=\S)\*(?!\*)|(?<![_\w])_(?=\S)[^_]+(?<=\S)_(?![_\w]))", Annotation),
            overlay(R"(`[^`]+`)", Code),
            overlay(R"(!?\[[^\]]*\]\([^)]*\)|<https?://[^>]+>)", Link),
            overlay(R"(^\s*([-*+]|\d+\.)(?=\s))", Operator, 1),
            overlay(R"(^\s*>.*$)", Comment),
            overlay(R"(^\s*(\*{3,}|-{3,}|_{3,})\s*$)", Punctuation),
            overlay(R"(\|)", Punctuation),
            overlay(R"(^\s*- \[[ xX]\])", Constant),
        };
        all << l;
    }
    {
        Language l = make("diff", "Diff", "#88dddd", "diff patch rej");
        l.scan = false;
        l.overlays = {
            overlay(R"(^\+.*$)", Inserted, 0, true, true),
            overlay(R"(^-.*$)", Deleted, 0, true, true),
            overlay(R"(^@@.*?@@)", Heading, 0, true, true),
            overlay(R"(^(diff |index |\+\+\+ |--- |new file|deleted file|similarity|rename ).*$)", Annotation, 0, true, true),
        };
        all << l;
    }

    // ── Build and infrastructure ─────────────────────────────────────────────────────────
    {
        Language l = make("dockerfile", "Dockerfile", "#2496ed", "dockerfile containerfile", "Dockerfile Containerfile");
        l.lineComments = { QStringLiteral("#") };
        l.quotes = { QStringLiteral("\""), QStringLiteral("'") };
        l.functions = false;
        l.members = false;
        l.overlays = {
            overlay(R"(^\s*(FROM|RUN|CMD|LABEL|MAINTAINER|EXPOSE|ENV|ADD|COPY|ENTRYPOINT|VOLUME|USER|WORKDIR|ARG|ONBUILD|STOPSIGNAL|HEALTHCHECK|SHELL)\b)",
                    Keyword, 1, false, false, true),
            overlay(R"(\bAS\b)", Keyword, 0, false, false, true),
            overlay(R"(\$\{[^}]*\}|\$[A-Za-z_]\w*)", Variable, 0, true),
            overlay(R"((?<=\s)--[\w-]+)", Attribute),
        };
        all << l;
    }
    {
        Language l = make("makefile", "Makefile", "#427819", "mk mak make", "Makefile GNUmakefile makefile BSDmakefile");
        l.lineComments = { QStringLiteral("#") };
        l.quotes = { QStringLiteral("\""), QStringLiteral("'") };
        l.keywords = words("ifeq ifneq ifdef ifndef else endif include sinclude define endef export unexport override vpath");
        l.functions = false;
        l.members = false;
        l.identExtra = QStringLiteral("-");
        l.overlays = {
            overlay(R"(^([\w.%/$() -]+?)(?=\s*::?(?!=)))", Function, 1),
            overlay(R"(^\s*([\w.-]+)\s*(?:[:+?!]?=))", Property, 1),
            overlay(R"(\$[({][^)}]*[)}]|\$[@<^+?*%])", Variable, 0, true),
            overlay(R"(^\.[A-Z]+)", Annotation),
        };
        all << l;
    }
    {
        Language l = make("cmake", "CMake", "#da3434", "cmake", "CMakeLists.txt CMakePresets.json");
        l.lineComments = { QStringLiteral("#") };
        l.blocks = { Block { QStringLiteral("#[["), QStringLiteral("]]"), Comment },
                     Block { QStringLiteral("[["), QStringLiteral("]]"), String } };
        l.quotes = { QStringLiteral("\"") };
        l.caseInsensitive = true;
        l.keywords = words("if elseif else endif foreach endforeach while endwhile function endfunction macro endmacro return "
                           "break continue block endblock", true);
        l.literals = words("on off true false yes no", true);
        l.members = false;
        l.identExtra = QStringLiteral("-");
        l.overlays = {
            overlay(R"(\$\{[^}]*\}|\$ENV\{[^}]*\})", Variable, 0, true),
            overlay(R"(\$<[^>]*>)", Annotation, 0, true),
        };
        all << l;
    }
    {
        Language l = make("hcl", "HCL / Terraform", "#844fba", "tf tfvars hcl nomad");
        l.lineComments = { QStringLiteral("#"), QStringLiteral("//") };
        l.blocks = { cBlockComment };
        l.quotes = { QStringLiteral("\"") };
        l.keywords = words("resource data variable output locals module provider terraform for in if for_each count depends_on lifecycle dynamic");
        l.types = words("string number bool list map set object tuple any");
        l.literals = words("true false null");
        l.members = true;
        l.overlays = {
            overlay(R"(^\s*([\w-]+)\s*=)", Property, 1),
            overlay(R"(\$\{[^}]*\})", Variable, 0, true),
        };
        all << l;
    }
    {
        Language l = make("glsl", "GLSL / HLSL", "#5686a5", "glsl vert frag geom comp tesc tese vs fs gs shader hlsl fx fxh");
        cLike(l);
        l.keywords = words("attribute const uniform varying buffer shared layout centroid flat smooth noperspective patch sample "
                           "break continue do for while switch case default if else in out inout return discard struct precision "
                           "highp mediump lowp invariant cbuffer register");
        l.types = words("void bool int uint float double vec2 vec3 vec4 ivec2 ivec3 ivec4 bvec2 bvec3 bvec4 uvec2 uvec3 uvec4 "
                        "mat2 mat3 mat4 sampler2D sampler3D samplerCube float2 float3 float4 float4x4 Texture2D SamplerState");
        l.literals = words("true false");
        l.builtins = words("gl_Position gl_FragCoord gl_FragColor texture mix clamp smoothstep step dot cross normalize length "
                           "sin cos pow abs min max fract floor");
        l.overlays = { overlay(R"(^\s*#\s*[A-Za-z_]+)", Annotation) };
        all << l;
    }
    {
        Language l = make("asm", "Assembly", "#6e4c13", "asm s nasm inc");
        l.lineComments = { QStringLiteral(";"), QStringLiteral("#") };
        l.commentNeedsSpace = false;
        l.quotes = { QStringLiteral("\""), QStringLiteral("'") };
        l.caseInsensitive = true;
        l.keywords = words("mov lea push pop add sub mul imul div idiv inc dec and or xor not shl shr cmp test jmp je jne jz jnz "
                           "jg jge jl jle ja jb call ret syscall int nop", true);
        l.builtins = words("rax rbx rcx rdx rsi rdi rbp rsp r8 r9 r10 r11 r12 r13 r14 r15 eax ebx ecx edx esi edi ebp esp "
                           "ax bx cx dx al bl cl dl", true);
        l.functions = false;
        l.members = false;
        l.overlays = {
            overlay(R"(^\s*[A-Za-z_.][\w.]*:)", Function),
            overlay(R"(^\s*(section|segment|global|extern|db|dw|dd|dq|resb|resw|equ|bits|default)\b|\.\w+)", Annotation, 0, false, false, true),
        };
        all << l;
    }
    {
        Language l = make("latex", "LaTeX", "#008080", "tex sty cls ltx bib dtx");
        l.lineComments = { QStringLiteral("%") };
        l.functions = false;
        l.members = false;
        l.numbers = true;
        l.operators = false;
        l.overlays = {
            overlay(R"(\\[A-Za-z@]+\*?)", Keyword),
            overlay(R"(\\(begin|end)\{([^}]*)\})", Type, 2),
            overlay(R"(\$[^$]*\$)", String),
            overlay(R"(\\[^A-Za-z])", Escape),
        };
        all << l;
    }

    return all;
}

// ── Themes ───────────────────────────────────────────────────────────────────────────────

struct ThemeSpec
{
    const char *id;
    const char *name;
    bool dark;
    // background, foreground, gutter, gutterText, gutterActive, currentLine, selection, panel, border, accent, searchMatch
    const char *ui[11];
    // keyword, type, builtin, function, string, escape, number, comment, constant, variable, property, operator,
    // punctuation, annotation, tag, attribute, heading, link, inserted, deleted, code, bracket1, bracket2, bracket3
    const char *tokens[24];
    bool italicComments;
    bool boldKeywords;
};

const ThemeSpec themeSpecs[] = {
    { "one-dark", "One Dark Pro", true,
      { "#282c34", "#abb2bf", "#282c34", "#495162", "#abb2bf", "#2c313c", "#3e4451", "#21252b", "#181a1f", "#61afef", "#d19a6660" },
      { "#c678dd", "#e5c07b", "#56b6c2", "#61afef", "#98c379", "#56b6c2", "#d19a66", "#7f848e", "#d19a66", "#e06c75",
        "#e06c75", "#56b6c2", "#abb2bf", "#e5c07b", "#e06c75", "#d19a66", "#e06c75", "#61afef", "#98c379", "#e06c75",
        "#98c379", "#e5c07b", "#c678dd", "#61afef" }, true, false },
    { "dracula", "Dracula", true,
      { "#282a36", "#f8f8f2", "#282a36", "#6272a4", "#f8f8f2", "#323443", "#44475a", "#21222c", "#191a21", "#bd93f9", "#ffb86c55" },
      { "#ff79c6", "#8be9fd", "#8be9fd", "#50fa7b", "#f1fa8c", "#ff79c6", "#bd93f9", "#6272a4", "#bd93f9", "#ffb86c",
        "#66d9ef", "#ff79c6", "#f8f8f2", "#50fa7b", "#ff79c6", "#50fa7b", "#bd93f9", "#8be9fd", "#50fa7b", "#ff5555",
        "#f1fa8c", "#f1fa8c", "#ff79c6", "#8be9fd" }, true, false },
    { "monokai", "Monokai", true,
      { "#272822", "#f8f8f2", "#272822", "#90908a", "#f8f8f2", "#3e3d32", "#49483e", "#1e1f1c", "#171814", "#a6e22e", "#e6db7455" },
      { "#f92672", "#66d9ef", "#66d9ef", "#a6e22e", "#e6db74", "#ae81ff", "#ae81ff", "#88846f", "#ae81ff", "#fd971f",
        "#66d9ef", "#f92672", "#f8f8f2", "#a6e22e", "#f92672", "#a6e22e", "#e6db74", "#66d9ef", "#a6e22e", "#f92672",
        "#e6db74", "#e6db74", "#f92672", "#66d9ef" }, true, false },
    { "tokyo-night", "Tokyo Night", true,
      { "#1a1b26", "#a9b1d6", "#1a1b26", "#3b4261", "#737aa2", "#1f2335", "#283457", "#16161e", "#101014", "#7aa2f7", "#ff9e6450" },
      { "#bb9af7", "#2ac3de", "#7dcfff", "#7aa2f7", "#9ece6a", "#89ddff", "#ff9e64", "#565f89", "#ff9e64", "#c0caf5",
        "#73daca", "#89ddff", "#a9b1d6", "#e0af68", "#f7768e", "#bb9af7", "#7aa2f7", "#73daca", "#9ece6a", "#f7768e",
        "#9ece6a", "#e0af68", "#bb9af7", "#7dcfff" }, true, false },
    { "catppuccin", "Catppuccin Mocha", true,
      { "#1e1e2e", "#cdd6f4", "#1e1e2e", "#45475a", "#b4befe", "#25263a", "#3a3c52", "#181825", "#11111b", "#cba6f7", "#f9e2af50" },
      { "#cba6f7", "#f9e2af", "#fab387", "#89b4fa", "#a6e3a1", "#f5c2e7", "#fab387", "#6c7086", "#fab387", "#f38ba8",
        "#89dceb", "#94e2d5", "#9399b2", "#f9e2af", "#89b4fa", "#f9e2af", "#f38ba8", "#89dceb", "#a6e3a1", "#f38ba8",
        "#a6e3a1", "#f9e2af", "#cba6f7", "#89b4fa" }, true, false },
    { "github-dark", "GitHub Dark", true,
      { "#0d1117", "#e6edf3", "#0d1117", "#6e7681", "#e6edf3", "#161b22", "#264f78", "#010409", "#30363d", "#2f81f7", "#bb800966" },
      { "#ff7b72", "#ffa657", "#79c0ff", "#d2a8ff", "#a5d6ff", "#79c0ff", "#79c0ff", "#8b949e", "#79c0ff", "#ffa657",
        "#79c0ff", "#ff7b72", "#e6edf3", "#d2a8ff", "#7ee787", "#79c0ff", "#79c0ff", "#a5d6ff", "#7ee787", "#ffa198",
        "#a5d6ff", "#e3b341", "#d2a8ff", "#79c0ff" }, false, false },
    { "nord", "Nord", true,
      { "#2e3440", "#d8dee9", "#2e3440", "#4c566a", "#d8dee9", "#3b4252", "#434c5e", "#272c36", "#242933", "#88c0d0", "#ebcb8b50" },
      { "#81a1c1", "#8fbcbb", "#88c0d0", "#88c0d0", "#a3be8c", "#ebcb8b", "#b48ead", "#616e88", "#b48ead", "#d8dee9",
        "#8fbcbb", "#81a1c1", "#eceff4", "#d08770", "#81a1c1", "#8fbcbb", "#88c0d0", "#88c0d0", "#a3be8c", "#bf616a",
        "#a3be8c", "#ebcb8b", "#b48ead", "#88c0d0" }, true, false },
    { "synthwave", "Synthwave '84", true,
      { "#262335", "#ffffff", "#262335", "#6d6a84", "#ffffff", "#2f2a45", "#463465", "#1e1a2b", "#171520", "#ff7edb", "#fede5d50" },
      { "#fede5d", "#fe4450", "#36f9f6", "#36f9f6", "#ff8b39", "#fede5d", "#f97e72", "#848bbd", "#f97e72", "#ff7edb",
        "#ff7edb", "#fede5d", "#ffffff", "#72f1b8", "#72f1b8", "#fede5d", "#ff7edb", "#36f9f6", "#72f1b8", "#fe4450",
        "#ff8b39", "#fede5d", "#ff7edb", "#36f9f6" }, true, true },
    { "github-light", "GitHub Light", false,
      { "#ffffff", "#1f2328", "#ffffff", "#8c959f", "#1f2328", "#f6f8fa", "#b6e3ff", "#f6f8fa", "#d0d7de", "#0969da", "#fff8c5" },
      { "#cf222e", "#953800", "#0550ae", "#8250df", "#0a3069", "#0550ae", "#0550ae", "#6e7781", "#0550ae", "#953800",
        "#0550ae", "#cf222e", "#1f2328", "#8250df", "#116329", "#0550ae", "#0550ae", "#0a3069", "#116329", "#82071e",
        "#0a3069", "#9a6700", "#8250df", "#0550ae" }, false, false },
    { "solarized-light", "Solarized Light", false,
      { "#fdf6e3", "#586e75", "#eee8d5", "#93a1a1", "#586e75", "#eee8d5", "#e4dcc4", "#eee8d5", "#d9d2bf", "#268bd2", "#b5890040" },
      { "#859900", "#b58900", "#268bd2", "#268bd2", "#2aa198", "#cb4b16", "#d33682", "#93a1a1", "#cb4b16", "#268bd2",
        "#6c71c4", "#859900", "#657b83", "#6c71c4", "#268bd2", "#b58900", "#cb4b16", "#268bd2", "#859900", "#dc322f",
        "#2aa198", "#b58900", "#d33682", "#268bd2" }, true, false },
};

// Specs use CSS-style "#RRGGBBAA"; QColor reads eight digits as "#AARRGGBB".
QColor specColor(const char *spec)
{
    const QString text = QString::fromLatin1(spec);
    if (text.size() != 9)
        return QColor(text);
    QColor color(text.left(7));
    color.setAlpha(text.mid(7).toInt(nullptr, 16));
    return color;
}

QList<Theme> buildThemes()
{
    QList<Theme> all;
    for (const ThemeSpec &spec : themeSpecs) {
        Theme t;
        t.id = QString::fromLatin1(spec.id);
        t.name = QString::fromUtf8(spec.name);
        t.dark = spec.dark;
        t.background   = specColor(spec.ui[0]);
        t.foreground   = specColor(spec.ui[1]);
        t.gutter       = specColor(spec.ui[2]);
        t.gutterText   = specColor(spec.ui[3]);
        t.gutterActive = specColor(spec.ui[4]);
        t.currentLine  = specColor(spec.ui[5]);
        t.selection    = specColor(spec.ui[6]);
        t.panel        = specColor(spec.ui[7]);
        t.border       = specColor(spec.ui[8]);
        t.accent       = specColor(spec.ui[9]);
        t.searchMatch  = specColor(spec.ui[10]);

        t.tokens[Plain] = t.foreground;
        for (int i = 0; i < 24; ++i)
            t.tokens[Keyword + i] = specColor(spec.tokens[i]);
        t.italicComments = spec.italicComments;
        t.boldKeywords = spec.boldKeywords;
        all << t;
    }
    return all;
}

} // namespace

const QList<Language> &languages()
{
    static const QList<Language> all = buildLanguages();
    return all;
}

const Language *findLanguage(const QString &id)
{
    for (const Language &language : languages())
        if (language.id == id)
            return &language;
    return nullptr;
}

QString detectLanguage(const QString &fileName, const QString &firstLine)
{
    static const auto indexes = [] {
        QHash<QString, QString> byExtension;
        QHash<QString, QString> byName;
        for (const Language &l : languages()) {
            for (const QString &ext : l.extensions)
                byExtension.insert(ext.toLower(), l.id);
            for (const QString &name : l.fileNames)
                byName.insert(name.toLower(), l.id);
        }
        return std::make_pair(byExtension, byName);
    }();

    const QString base = QFileInfo(fileName).fileName();
    const QString lower = base.toLower();

    if (const auto it = indexes.second.constFind(lower); it != indexes.second.constEnd())
        return it.value();
    if (lower.startsWith(QStringLiteral("dockerfile")) || lower.startsWith(QStringLiteral("containerfile")))
        return QStringLiteral("dockerfile");
    if (lower.startsWith(QStringLiteral("makefile")))
        return QStringLiteral("makefile");

    const int dot = lower.lastIndexOf(QLatin1Char('.'));
    if (dot >= 0 && dot < lower.size() - 1) {
        if (const auto it = indexes.first.constFind(lower.mid(dot + 1)); it != indexes.first.constEnd())
            return it.value();
    }

    const QString head = firstLine.trimmed();
    if (head.startsWith(QStringLiteral("#!"))) {
        if (head.contains(QStringLiteral("python")))                                     return QStringLiteral("python");
        if (head.contains(QStringLiteral("node")) || head.contains(QStringLiteral("deno"))) return QStringLiteral("javascript");
        if (head.contains(QStringLiteral("ruby")))                                       return QStringLiteral("ruby");
        if (head.contains(QStringLiteral("perl")))                                       return QStringLiteral("perl");
        if (head.contains(QStringLiteral("php")))                                        return QStringLiteral("php");
        if (head.contains(QStringLiteral("pwsh")) || head.contains(QStringLiteral("powershell"))) return QStringLiteral("powershell");
        if (head.contains(QStringLiteral("lua")))                                        return QStringLiteral("lua");
        return QStringLiteral("shell");
    }
    if (head.startsWith(QStringLiteral("<?xml")))
        return QStringLiteral("xml");
    if (head.startsWith(QStringLiteral("<!DOCTYPE html"), Qt::CaseInsensitive) || head.startsWith(QStringLiteral("<html"), Qt::CaseInsensitive))
        return QStringLiteral("html");
    if (head.startsWith(QStringLiteral("<?php")))
        return QStringLiteral("php");
    return QStringLiteral("plaintext");
}

const QList<Theme> &themes()
{
    static const QList<Theme> all = buildThemes();
    return all;
}

const Theme &findTheme(const QString &id)
{
    for (const Theme &theme : themes())
        if (theme.id == id)
            return theme;
    return themes().first();
}

} // namespace CodeViewer
