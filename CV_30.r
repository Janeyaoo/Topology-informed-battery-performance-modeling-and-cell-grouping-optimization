install.packages("ggplot2")
install.packages("dplyr")
install.packages("openxlsx")
install.packages("readxl")
install.packages("tidyverse")
install.packages("languageserver")

library(readxl)
library(dplyr)
library(ggplot2)
library(openxlsx)

# === 路径设置 ===
battery_files <- list(
  "Battery 1" = "/home/newuser/Documents/NDP/Battery/Battery_data/LISHEN/LISHEN_LFP_1.0C-2.0D_T25_1/LISHEN_LFP_1.0C-2.0D_T25_1.xlsx",
  "Battery 2" = "/home/newuser/Documents/NDP/Battery/Battery_data/LISHEN/LISHEN_LFP_1.0C-2.0D_T25_2/LISHEN_LFP_1.0C-2.0D_T25_2.xlsx",
  "Battery 3" = "/home/newuser/Documents/NDP/Battery/Battery_data/LISHEN/LISHEN_LFP_1.0C-2.0D_T25_3/LISHEN_LFP_1.0C-2.0D_T25_3.xlsx",
  "Battery 4" = "/home/newuser/Documents/NDP/Battery/Battery_data/LISHEN/LISHEN_LFP_1.0C-2.0D_T25_4/LISHEN_LFP_1.0C-2.0D_T25_4.xlsx",
  "Battery 5" = "/home/newuser/Documents/NDP/Battery/Battery_data/LISHEN/LISHEN_LFP_1.0C-2.0D_T25_5/LISHEN_LFP_1.0C-2.0D_T25_5.xlsx",
  "Battery 6" = "/home/newuser/Documents/NDP/Battery/Battery_data/LISHEN/LISHEN_LFP_1.0C-2.0D_T25_6/LISHEN_LFP_1.0C-2.0D_T25_6.xlsx",
  "Battery 7" = "/home/newuser/Documents/NDP/Battery/Battery_data/LISHEN/LISHEN_LFP_1.0C-2.0D_T25_7/LISHEN_LFP_1.0C-2.0D_T25_7.xlsx",
  "Battery 8" = "/home/newuser/Documents/NDP/Battery/Battery_data/LISHEN/LISHEN_LFP_1.0C-2.0D_T25_8/LISHEN_LFP_1.0C-2.0D_T25_8.xlsx"
)

dir.create("cv_plots", showWarnings = FALSE)

# === 计算 CV 核心函数 ===
compute_cv_by_state <- function(df, state_filter) {
  df_filtered <- df %>%
    filter(grepl(state_filter, State, ignore.case = TRUE)) %>%
    group_by(Cycle) %>%
    summarize(
      mean_v = mean(`Voltage(V)`, na.rm = TRUE),
      sd_v = sd(`Voltage(V)`, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(!is.na(mean_v), mean_v != 0) %>%
    mutate(std_to_mean_ratio = sd_v / mean_v)
  return(df_filtered)
}

# === 主循环 ===
cv_summary_list <- list()

for (battery_name in names(battery_files)) {
  cat("Processing", battery_name, "...\n")
  path <- battery_files[[battery_name]]

  # 读取第3个工作表，仅所需列
  sheet_names <- excel_sheets(path)
  df <- read_excel(path, sheet = sheet_names[3]) %>%
    select(Cycle, State, `Voltage(V)`)

  # 分状态筛选
  df_charge <- df %>%
    filter(grepl("Chg", State, ignore.case = TRUE) &
             !grepl("DChg", State, ignore.case = TRUE))
  df_dchg <- df %>% filter(grepl("DChg", State, ignore.case = TRUE))
  df_rest <- df %>% filter(grepl("Rest", State, ignore.case = TRUE))

  # 计算 CV
  cv_charge <- compute_cv_by_state(df_charge, "Chg")
  cv_dchg <- compute_cv_by_state(df_dchg, "DChg")
  cv_rest <- compute_cv_by_state(df_rest, "Rest")

  # 仅保留前30循环
  cv_charge <- cv_charge %>% filter(Cycle <= 30)
  cv_dchg <- cv_dchg %>% filter(Cycle <= 30)
  cv_rest <- cv_rest %>% filter(Cycle <= 30)

  # 汇总数据
  for (i in 1:30) {
    row <- data.frame(
      Battery = battery_name,
      Cycle = i,
      CV_Charge = cv_charge %>% filter(Cycle == i) %>% pull(std_to_mean_ratio) * 1000 %>% {ifelse(length(.) == 0, NA, .)},
      CV_Discharge = cv_dchg %>% filter(Cycle == i) %>% pull(std_to_mean_ratio) * 1000 %>% {ifelse(length(.) == 0, NA, .)},
      CV_Rest = cv_rest %>% filter(Cycle == i) %>% pull(std_to_mean_ratio) * 1000 %>% {ifelse(length(.) == 0, NA, .)}
    )
    cv_summary_list[[length(cv_summary_list) + 1]] <- row
  }

  # 绘图并保存
  plot_df <- bind_rows(
    cv_charge %>% mutate(State = "Charge"),
    cv_dchg %>% mutate(State = "Discharge"),
    cv_rest %>% mutate(State = "Rest")
  ) %>% mutate(std_to_mean_ratio = std_to_mean_ratio * 1000)

  p <- ggplot(plot_df, aes(x = Cycle, y = std_to_mean_ratio, color = State, shape = State)) +
    geom_line() + geom_point() +
    labs(title = paste("CV Curve for", battery_name),
         x = "Cycle Number", y = "CV (std/mean ×1000)") +
    theme_minimal()

  ggsave(filename = paste0("cv_plots/", gsub(" ", "_", battery_name), "_cv_plot.png"),
         plot = p, width = 8, height = 5)
}

# === 导出汇总表 ===
cv_df <- bind_rows(cv_summary_list)
write.xlsx(cv_df, "cv_summary_first30.xlsx")
cat("✅ 已保存为 cv_summary_first30.xlsx 和图像。\n")
