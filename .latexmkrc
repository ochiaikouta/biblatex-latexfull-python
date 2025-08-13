# upLaTeX + upBibTeX + jplain.bst 用の設定

# 出力先と動作モード
$out_dir = 'tex';
$aux_dir = 'tex';
$pdf_mode = 3;



# CI 環境用の分岐
if ($ENV{'CI'}) {
  # graphicx の demo オプションを有効化するために \CI 定義を注入
  $latex = 'uplatex -kanji=utf8 -interaction=nonstopmode -file-line-error -synctex=1 %O "\\def\\CI{1}\\input{%S}"';
}


# uplatex + dvipdfmx
$latex = 'uplatex -kanji=utf8 -interaction=nonstopmode -file-line-error -synctex=1 %O %S';
$dvipdf = 'dvipdfmx %O -o %D %S';

# upbibtex
$bibtex_use = 1;
$bibtex = 'upbibtex %O %B';

# 環境変数
$ENV{'TEXINPUTS'} = './//:' . ($ENV{'TEXINPUTS'} || '');
$ENV{'BIBINPUTS'} = './//:' . ($ENV{'BIBINPUTS'} || '');

# clean
$clean_ext = 'aux log toc out lot lof nav snm vrb xdv synctex.gz bcf run.xml blg fls fdb_latexmk';
$clean_full_ext = $clean_ext . ' pdf dvi bbl swp';

# その他設定
$preview_continuous_mode = 0;
$silence_logfile_warnings = 1;
$force_mode = 1;
$synctex = 1;
$recorder = 1;
