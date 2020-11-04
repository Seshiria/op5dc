/*
 * An flicker free driver based on Qcom MDSS for OLED devices
 *
 * Copyright (C) 2012-2014, The Linux Foundation. All rights reserved.
 * Copyright (C) Sony Mobile Communications Inc. All rights reserved.
 * Copyright (C) 2014-2018, AngeloGioacchino Del Regno <kholk11@gmail.com>
 * Copyright (C) 2018, Devries <therkduan@gmail.com>
 * Copyright (C) 2019-2020, Tanish <tanish2k09.dev@gmail.com>
 * Copyright (C) 2020, shxyke <shxyke@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */

#ifndef _FLICKER_FREE_H
#define _FLICKER_FREE_H
#include <uapi/linux/msm_mdp.h>

#define FF_MAX_SCALE 32768 /* Maximum value of RGB possible */

#define FF_MIN_SCALE 5120 /* Minimum value of RGB recommended */

#define RET_WORKGROUND_DELAY 200

#define BACKLIGHT_INDEX 66

/* with this function you can set the flicker free into enabled or disabled */
void set_flicker_free(bool enabled);

/* you can use this function to remap the phisical backlight level */
u32 mdss_panel_calc_backlight(u32 bl_lvl);

/* set the minimum backlight value that does not flicker on your device */
void set_elvss_off_threshold(int value);

/* get the current elvss value */
int get_elvss_off_threshold(void);

/* get the current flicker free status (enabled or disabled) */
bool if_flicker_free_enabled(void);

void pcc_v1_7_combine(struct mdp_pcc_data_v1_7 **raw,
		struct mdp_pcc_data_v1_7 **user,
		struct mdp_pcc_data_v1_7 **real);

void pcc_combine(struct mdp_pcc_cfg_data *raw,
		struct mdp_pcc_cfg_data *user,
		struct mdp_pcc_cfg_data *real);

#endif  /* _FLICKER_FREE_H */
