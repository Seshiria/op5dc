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

#include <linux/module.h>
#include <linux/device.h>
#include <linux/init.h>
#include <linux/rtc.h>
#include <linux/timer.h>
#include <linux/kernel.h>
#include <linux/delay.h>

#include "flicker_free.h"
#include "mdss_fb.h"
#include "mdss_mdp.h"

struct mdss_panel_data *pdata;
struct mdp_pcc_cfg_data pcc_config;
struct mdp_pcc_data_v1_7 *payload;
struct mdp_dither_cfg_data dither_config;
struct mdp_dither_data_v1_7 *dither_payload;
u32 copyback = 0;
u32 dither_copyback = 0;
static u32 backlight = 0;
static const u32 pcc_depth[9] = {128,256,512,1024,2048,4096,8192,16384,32768};
static u32 depth = 8;
static bool pcc_enabled = false;
static bool mdss_backlight_enable = false;

static int bkl_to_pcc[BACKLIGHT_INDEX] = {42, 56, 67, 75, 84, 91, 98, 104,
	109, 114, 119, 124, 128, 133, 136, 140, 143, 146, 150, 152, 156, 159,
	162, 165, 168, 172, 176, 178, 181, 184, 187, 189, 192, 194, 196, 199,
	202, 204, 206, 209, 211, 213, 215, 217, 220, 222, 224, 226, 228, 230,
	233, 236, 237, 239, 241, 241, 243, 245, 246, 249, 249, 250, 252, 254, 255, 256};

/* Constants - Customize as needed */
static int elvss_off_threshold = 66; /* Minimum backlight value that does not flicker */

static struct delayed_work back_to_backlight_work;
static void back_to_backlight(struct work_struct *work)
{
		pdata = dev_get_platdata(&get_mfd_copy()->pdev->dev);
		pdata->set_backlight(pdata,backlight);
		return;
}

static int flicker_free_push_dither(int depth)
{
	dither_config.flags = mdss_backlight_enable ?
		MDP_PP_OPS_WRITE | MDP_PP_OPS_ENABLE :
			MDP_PP_OPS_WRITE | MDP_PP_OPS_DISABLE;
	dither_config.r_cr_depth = depth;
	dither_config.g_y_depth = depth;
	dither_config.b_cb_depth = depth;
	dither_payload->len = 0;
	dither_payload->temporal_en = 0;
	dither_payload->r_cr_depth = dither_config.r_cr_depth;
	dither_payload->g_y_depth = dither_config.g_y_depth;
	dither_payload->b_cb_depth = dither_config.b_cb_depth;
	dither_config.cfg_payload = dither_payload;

	return mdss_mdp_dither_config(get_mfd_copy(),&dither_config,&dither_copyback,1);
}

static int flicker_free_push_pcc(int temp)
{
	pcc_config.ops = pcc_enabled ? 
		MDP_PP_OPS_WRITE | MDP_PP_OPS_ENABLE :
			MDP_PP_OPS_WRITE | MDP_PP_OPS_DISABLE;
	pcc_config.r.r = temp;
	pcc_config.g.g = temp;
	pcc_config.b.b = temp;
	payload->r.r = pcc_config.r.r;
	payload->g.g = pcc_config.g.g;
	payload->b.b = pcc_config.b.b;
	pcc_config.cfg_payload = payload;
	
	return mdss_mdp_kernel_pcc_config(get_mfd_copy(), &pcc_config, &copyback);
}

static int set_brightness(int backlight)
{
	uint32_t temp = 0;
	backlight = clamp_t(int, ((backlight-1)*(BACKLIGHT_INDEX-1)/(elvss_off_threshold-1)+1), 1, BACKLIGHT_INDEX);
	temp = clamp_t(int, 0x80*bkl_to_pcc[backlight - 1], FF_MIN_SCALE, FF_MAX_SCALE);
	for (depth = 8;depth >= 1;depth--){
		if(temp >= pcc_depth[depth]) break;
	}
	flicker_free_push_dither(depth);
	return flicker_free_push_pcc(temp);
}

u32 mdss_panel_calc_backlight(u32 bl_lvl)
{
	if (mdss_backlight_enable && bl_lvl != 0 && bl_lvl < elvss_off_threshold) {
		pr_debug("flicker free mode on\n");
		pr_debug("elvss_off = %d\n", elvss_off_threshold);
		pcc_enabled = true;
		if(!set_brightness(bl_lvl))
			return elvss_off_threshold;
	}else{
		if(bl_lvl && pcc_enabled){
			pcc_enabled = false;
			set_brightness(elvss_off_threshold);
		}
	}
	return bl_lvl;
}


void set_flicker_free(bool enabled)
{
	if(mdss_backlight_enable == enabled) return;
	mdss_backlight_enable = enabled;
	if (get_mfd_copy())
		pdata = dev_get_platdata(&get_mfd_copy()->pdev->dev);
	else return;
	if (enabled){
		if ((pdata) && (pdata->set_backlight)){
			backlight = mdss_panel_calc_backlight(get_bkl_lvl()); 
			cancel_delayed_work_sync(&back_to_backlight_work);
			schedule_delayed_work(&back_to_backlight_work, msecs_to_jiffies(RET_WORKGROUND_DELAY));
		}else return;
	}else{
		if ((pdata) && (pdata->set_backlight)){
			backlight = get_bkl_lvl();
			pdata->set_backlight(pdata,backlight);
			mdss_panel_calc_backlight(backlight);
		}else return;
	}
} 

void set_elvss_off_threshold(int value)
{
	elvss_off_threshold = value;
}

int get_elvss_off_threshold(void)
{
	return elvss_off_threshold;
}

bool if_flicker_free_enabled(void)
{
	return mdss_backlight_enable;
}

static u32 pcc_rescale(u32 raw, u32 user)
{
	u32 val = 0;

	if (raw == 0 || raw > 32768)
		raw = 32768;
	if (user == 0 || user > 32768)
		user = 32768;
	val = (raw * user) / 32768;
	return val < 2560 ? 2560 : val;
}

void pcc_v1_7_combine(struct mdp_pcc_data_v1_7 **raw,
		struct mdp_pcc_data_v1_7 **user,
		struct mdp_pcc_data_v1_7 **real)
{
	struct mdp_pcc_data_v1_7 *real_cpy;
	real_cpy = kzalloc(sizeof(struct mdp_pcc_data_v1_7), GFP_USER);
	if (!(*real)) {
		*real = kzalloc(sizeof(struct mdp_pcc_data_v1_7), GFP_USER);
		if (!(*real)) {
			pr_err("%s: alloc failed!", __func__);
			return;
		}
	}
	if((*raw)&&(*user)){
		real_cpy->r.c = (*user)->r.c? pcc_rescale((*raw)->r.r, (*user)->r.c)*3/4: 0;
		real_cpy->r.r = (*user)->r.g? pcc_rescale((*raw)->r.r, (*user)->r.r)*3/4: pcc_rescale((*raw)->r.r, (*user)->r.r);
		real_cpy->r.g = (*user)->r.g? pcc_rescale((*raw)->r.r, (*user)->r.g)*3/4: 0;
		real_cpy->r.b = (*user)->r.b? pcc_rescale((*raw)->r.r, (*user)->r.b)*3/4: 0;
		real_cpy->r.rg = (*user)->r.rg? pcc_rescale((*raw)->r.r, (*user)->r.rg)*3/4: 0;
		real_cpy->r.gb = (*user)->r.gb? pcc_rescale((*raw)->r.r, (*user)->r.gb)*3/4: 0;
		real_cpy->r.rb = (*user)->r.rb? pcc_rescale((*raw)->r.r, (*user)->r.rb)*3/4: 0;
		real_cpy->r.rgb = (*user)->r.rgb? pcc_rescale((*raw)->r.r, (*user)->r.rgb)*3/4: 0;
		real_cpy->g.c = (*user)->g.c? pcc_rescale((*raw)->r.r, (*user)->g.c)*3/4: 0;
		real_cpy->g.g = (*user)->g.r? pcc_rescale((*raw)->r.r, (*user)->g.g)*3/4: pcc_rescale((*raw)->r.r, (*user)->g.g);
		real_cpy->g.r = (*user)->g.r? pcc_rescale((*raw)->r.r, (*user)->g.r)*3/4: 0;
		real_cpy->g.b = (*user)->g.b? pcc_rescale((*raw)->r.r, (*user)->g.b)*3/4: 0;
		real_cpy->g.rg = (*user)->g.rg? pcc_rescale((*raw)->r.r, (*user)->g.rg)*3/4: 0;
		real_cpy->g.gb = (*user)->g.gb? pcc_rescale((*raw)->r.r, (*user)->g.gb)*3/4: 0;
		real_cpy->g.rb = (*user)->g.rb? pcc_rescale((*raw)->r.r, (*user)->g.rb)*3/4: 0;
		real_cpy->g.rgb = (*user)->g.rgb? pcc_rescale((*raw)->r.r, (*user)->g.rgb)*3/4: 0;
		real_cpy->b.c = (*user)->b.c? pcc_rescale((*raw)->r.r, (*user)->b.c)*3/4: 0;
		real_cpy->b.b = (*user)->b.r? pcc_rescale((*raw)->r.r, (*user)->b.b)*3/4: pcc_rescale((*raw)->r.r, (*user)->b.b);
		real_cpy->b.r = (*user)->b.r? pcc_rescale((*raw)->r.r, (*user)->b.r)*3/4: 0;
		real_cpy->b.g = (*user)->b.g? pcc_rescale((*raw)->r.r, (*user)->b.g)*3/4: 0;
		real_cpy->b.rg = (*user)->b.rg? pcc_rescale((*raw)->r.r, (*user)->b.rg)*3/4: 0;
		real_cpy->b.gb = (*user)->b.gb? pcc_rescale((*raw)->r.r, (*user)->b.gb)*3/4: 0;
		real_cpy->b.rb = (*user)->b.rb? pcc_rescale((*raw)->r.r, (*user)->b.rb)*3/4: 0;
		real_cpy->b.rgb = (*user)->b.rgb? pcc_rescale((*raw)->r.r, (*user)->b.rgb)*3/4: 0;
	}else{
		if((*user)){
			memcpy(real_cpy, (*user), sizeof(struct mdp_pcc_data_v1_7));
		}else{
			if((*raw)){
				real_cpy->r.r = (*raw)->r.r;
				real_cpy->g.g = (*raw)->g.g;
				real_cpy->b.b = (*raw)->b.b;
			}else{
				real_cpy->r.r = 32768;
				real_cpy->g.g = 32768;
				real_cpy->b.b = 32768;
			}
		}
	}
	memcpy(*real, real_cpy, sizeof(struct mdp_pcc_data_v1_7));
	kfree(real_cpy);
}

void pcc_combine(struct mdp_pcc_cfg_data *raw,
		struct mdp_pcc_cfg_data *user,
		struct mdp_pcc_cfg_data *real)
{
	uint32_t r_ops, u_ops, r_en, u_en;
	struct mdp_pcc_data_v1_7 *v17_ff_data, *v17_user_data,
				*v17_real_data,*payload;

	if (!real) {
		real = kzalloc(sizeof(struct mdp_pcc_cfg_data), GFP_KERNEL);
		payload = kzalloc(sizeof(struct mdp_pcc_data_v1_7), GFP_USER);
		payload->r.r = payload->g.g = payload->b.b = 32768;
		real->cfg_payload = payload;
		if (!real) {
			pr_err("%s: alloc failed!", __func__);
			return;
		}
	}

	real->version = mdp_pcc_v1_7;
	real->block = MDP_LOGICAL_BLOCK_DISP_0;

	r_ops = raw->cfg_payload ? raw->ops : MDP_PP_OPS_DISABLE;
	u_ops = user->cfg_payload ? user->ops : MDP_PP_OPS_DISABLE;
	r_en = raw && !(raw->ops & MDP_PP_OPS_DISABLE);
	u_en = user && !(user->ops & MDP_PP_OPS_DISABLE);

	// user configuration may change often, but the raw configuration
	// will correspond to calibration data which should only change if
	// there is a mode switch. we only care about the base
	// coefficients from the user config.

	if (!r_en || (raw->r.r == 0 && raw->g.g == 0 && raw->b.b == 0)){
		raw->r.r = raw->g.g = raw->b.b = 32768;
	}
	if (!u_en || (user->r.r == 0 && user->g.g == 0 && user->b.b ==0)){
		user->r.r = user->g.g = user->b.b = 32768;
	}

	
	real->r.r = pcc_rescale(raw->r.r, user->r.r);
	real->g.g = pcc_rescale(raw->g.g, user->g.g);
	real->b.b = pcc_rescale(raw->b.b, user->b.b);
	v17_ff_data = raw->cfg_payload;
	v17_user_data = user->cfg_payload;
	v17_real_data = real->cfg_payload;
	pcc_v1_7_combine(&v17_ff_data, &v17_user_data, &v17_real_data);
	if (r_en && u_en)
		real->ops = r_ops | u_ops;
	else if (r_en)
		real->ops = r_ops;
	else if (u_en)
		real->ops = u_ops;
	else
		real->ops = MDP_PP_OPS_DISABLE;
}

static int __init flicker_free_init(void)
{
	memset(&pcc_config, 0, sizeof(struct mdp_pcc_cfg_data));
	pcc_config.version = mdp_pcc_v1_7;
	pcc_config.block = MDP_LOGICAL_BLOCK_DISP_0;
	payload = kzalloc(sizeof(struct mdp_pcc_data_v1_7),GFP_USER);
	memset(&dither_config, 0, sizeof(struct mdp_dither_cfg_data));
	dither_config.version = mdp_dither_v1_7;
	dither_config.block = MDP_LOGICAL_BLOCK_DISP_0;
	dither_payload = kzalloc(sizeof(struct mdp_dither_data_v1_7),GFP_USER);
	INIT_DELAYED_WORK(&back_to_backlight_work, back_to_backlight);
	return 0;
}

static void __exit flicker_free_exit(void)
{
	kfree(payload);
	kfree(dither_payload);
}

late_initcall(flicker_free_init);
module_exit(flicker_free_exit);