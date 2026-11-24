# %% Zachos Plot
zachos_plot = (
     ggplot(df, aes(x="age_ka", y="d18O"))
     + geom_point(size=1, alpha=0.7)
     + geom_line(data=smoothed_df, color="firebrick", size=1)
     + scale_x_reverse()
     + scale_y_reverse()
     + labs(
         x="Age (ka)",
         y="δ¹⁸O (‰)",
         title="Oxygen Changes Through Time",
     )
    + theme_tufte()
)
zachos_plot.show()
