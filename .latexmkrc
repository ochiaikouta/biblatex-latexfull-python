$out_dir = 'build';
$pdf_mode = 4;  # LuaLaTeXを使用
$bibtex_use = 2;

# LuaLaTeX コマンドを明示的に定義
$lualatex = 'lualatex -interaction=nonstopmode -file-line-error -shell-escape -synctex=1 %O %S';

# 入力ファイルの検索パスを設定
$ENV{'TEXINPUTS'} = './tex//:' . ($ENV{'TEXINPUTS'} || '');
$ENV{'BIBINPUTS'} = './tex//:' . ($ENV{'BIBINPUTS'} || '');

@clean_ext = qw(
  aux log toc out lot lof nav snm vrb xdv
  synctex.gz bcf run.xml bbl blg
  fls fdb_latexmk
);
@clean_full_ext = (@clean_ext, 'pdf');

$preview_continuous_mode = 0;
$silence_logfile_warnings = 1;
$force_mode = 1;

# SyncTeX を確実に生成
$postscript_mode = 0;
$dvi_mode = 0;

# 同期ファイルを強制的に build に出力
$synctex = 1;


