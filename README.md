# tsrexplorer

## Installing TSRexplorer

```
devtools::install_github("rpolicastro/tsrexplorer")
```

## Using TSRexplorer

Load tsrexplorer

```
library("tsrexplorer")
```

Load example data

```
TSSs <- system.file("extdata", "yeast_TSSs.RDS", package="tsrexplorer")
annotation <- system.file("extdata", "yeast_annotation.gtf", package="tsrexplorer")
assembly <- system.file("extdata", "yeast_assembly.fasta", package="tsrexplorer")
```


create tsr object

```
exp <- tsr_explorer(TSSs)
```

tmm normalize counts

```
exp <- normalize(exp)
```

generate tss correlation matrix

```
corr_plot <- plot_tss_corr(exp, corr_metric="pearson")

ggsave("tss_corr.png", corr_plot, device="png", type="cairo", height=5.5, width=7)
```

generate tss scatter plots

```
scatter_plot <- plot_tss_scatter(exp, sample_1 = "S288C-unpooled_WT-100ng_1", sample_2 = "S288C-unpooled_WT-100ng_2")

ggsave("tss_scatter.png", scatter_plot, device="png", type="cairo", height=3, width=3)
```

