-- OBS Studio counter script v1.0.1
-- This script is released under MIT License.
-- Author Kagua Kurusu, project homepage https://github.com/KaguaKurusu/counter4obs

obs = obslua

source_name = ""
prefix = ""
suffix = ""
num_of_chg = 0
current_num = 0
start_num = 0
hotkeys ={}
activated = false

-- Make text
function set_text(source, num)
	local text = prefix .. num .. suffix
	local settings = obs.obs_data_create()

	obs.obs_data_set_string(settings, "text", text)
	obs.obs_source_update(source, settings)
	obs.obs_data_release(settings)
end

-- Set datas when a set button is clicked
function set_button_clicked()
	local source = obs.obs_get_source_by_name(source_name)

	if source ~= nil then
		local active = obs.obs_source_showing(source)
		obs.obs_source_release(source)

		if active then
			current_num = start_num
			set_text(source, current_num)
		end
	end
end

-- Update text
function counter_update(type)
	local source = obs.obs_get_source_by_name(source_name)

	if source ~= nil then
		local active = obs.obs_source_showing(source)
		obs.obs_source_release(source)

		if active then
			if type == "countup" then
				current_num = current_num + num_of_chg
			elseif type == "countdown" then
				current_num = current_num - num_of_chg
			end

			set_text(source, current_num)
		end
	end
end

-- Register hotkeys
function reg_hotkey(settings)
	for k,v in pairs({countup="カウントアップ", countdown="カウントダウン"}) do
		hotkeys[k] = obs.obs_hotkey_register_frontend(k, v, function(pressed)
			if pressed then
				counter_update(k)
			end
		end)

		local a = obs.obs_data_get_array(settings, k)
		obs.obs_hotkey_load(hotkeys[k], a)
		obs.obs_data_array_release(a)
	end
end

function activate(activating)
	if activated == activating then
		return
	end

	activated = activating
end

function activate_signal(cd, activating)
	local source = obs.calldata_source(cd, "source ")

	if source ~= nil then
		local name = obs.obs_source_showing(source)

		if name == source_name then
			activate(activating)
		end
	end
end

function source_activated(cd)
	activate_signal(cd, true)
end

function source_deactivated(cd)
	activate_signal(cd, false)
end

function reset()
	activate(false)
	local source = obs.obs_get_source_by_name(source_name)

	if source ~= nil then
		local active = obs.obs_source_showing(source)
		obs.obs_source_release(source)
		activate(active)
	end
end

function script_description()
	return "ホットキーでテキストソースの数字をカウントアップ/ダウンするスクリプト。\
\
	数値前の文字および数値後の文字はオプションです。"
end

function script_properties()
	local props = obs.obs_properties_create()
	local p = obs.obs_properties_add_list(props, "source", "テキストソース", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()

	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_id(source)

			if source_id == "text_gdiplus" or source_id == "text_ft2_source" or source_id == "text_gdiplus_v2" or source_id == "text_ft2_source_v2" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			end
		end
	end

	obs.source_list_release(sources)

	obs.obs_properties_add_text(props, "prefix", "数値前の文字", obs.OBS_TEXT_MULTILINE)
	obs.obs_properties_add_text(props, "suffix", "数値後の文字", obs.OBS_TEXT_MULTILINE)
	obs.obs_properties_add_int(props, "num_of_chg", "増減数", 1, 100, 1)
	obs.obs_properties_add_int(props, "start_num", "開始値", 0, 100, 1)
	obs.obs_properties_add_button(props, "set_btn", "セット", set_button_clicked)
	obs.obs_properties_add_button(props, "cntup_btn", "カウントアップ", function(object, button)
		counter_update("countup")
	end)
	obs.obs_properties_add_button(props, "cntdown_btn", "カウントダウン", function(object, button)
		counter_update("countdown")
	end)

	return props
end

function script_defaults(settings)
	obs.obs_data_set_default_int(settings, "num_of_chg", 1)
	obs.obs_data_set_default_int(settings, 'start_num', 0)
	obs.obs_data_set_default_string(settings, "hotkey_up", "+")
	obs.obs_data_set_default_string(settings, "hotkey_down", "-")
end

function script_update(settings)
	activate(false)

	source_name = obs.obs_data_get_string(settings, "source")
	prefix = obs.obs_data_get_string(settings, "prefix")
	suffix = obs.obs_data_get_string(settings, "suffix")
	num_of_chg = obs.obs_data_get_int(settings, "num_of_chg")
	start_num = obs.obs_data_get_int(settings, "start_num")

	reset()
end

function script_load(settings)
	local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "source_show", source_activated)
	obs.signal_handler_connect(sh, "source_hide", source_deactivated)

	reg_hotkey(settings)
end

function script_save(settings)
	for k,v in pairs(hotkeys) do
		local hotkey_save_array = obs.obs_hotkey_save(v)
		obs.obs_data_set_array(settings, k, hotkey_save_array)
		obs.obs_data_array_release(hotkey_save_array)
	end
end
