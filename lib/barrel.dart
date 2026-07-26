export 'package:flutter/material.dart';
export 'dart:async';
export 'dart:convert';
export 'package:shared_preferences/shared_preferences.dart';
export 'package:equatable/equatable.dart';
export 'package:swappro/features/auth/models/token_model.dart';
export 'package:swappro/features/auth/services/token_service.dart';
export 'package:swappro/features/auth/services/session_aware_http_client.dart';
export 'package:swappro/features/home/services/api_service.dart';
export 'package:swappro/features/home/bloc/swap_request_cubit.dart';
export 'package:swappro/features/home/bloc/swap_bay_cubit.dart';
export 'package:swappro/config/app_config.dart';
export 'package:flutter_secure_storage/flutter_secure_storage.dart';
export 'package:swappro/config/glob_navigator.dart';

// bloc imports
export 'package:swappro/features/auth/bloc/auth_bloc.dart';
export 'package:swappro/common_bloc/theme_bloc.dart';
export 'package:swappro/common_bloc/theme_state.dart';
export 'package:swappro/common_bloc/success_bloc.dart';
export 'package:swappro/common_bloc/success_event.dart';
export 'package:swappro/common_bloc/success_state.dart';

// export google fonts
export 'package:google_fonts/google_fonts.dart';

// Screen Imports
export 'package:swappro/features/auth/logorsign.dart';
export 'package:swappro/features/admin/admin_signin.dart';
export 'package:swappro/features/admin/admin_dashboard.dart';
export 'package:swappro/features/initial_ui/splash.dart';
export 'package:swappro/features/auth/signin.dart';
export 'package:swappro/features/auth/signup.dart';
export 'package:swappro/features/auth/signup_otp.dart';
export 'package:swappro/features/initial_ui/initial.dart';
export 'package:swappro/features/initial_ui/server_error_page.dart';
export 'package:swappro/services/connectivity_notifier.dart';
export 'package:swappro/services/backend_connectivity.dart';
export 'package:swappro/services/api_error_handler.dart';
export 'package:swappro/services/geocoding_service.dart';
export 'package:swappro/features/home/listing_location.dart';
export 'package:swappro/features/home/home.dart';
export 'package:swappro/features/home/search_filters.dart';
export 'package:swappro/features/home/search_properties.dart';
export 'package:swappro/features/home/dash_listings.dart';
export 'package:swappro/features/home/listing_image.dart';
export 'package:swappro/features/home/property_detail.dart';
export 'package:swappro/features/home/property_swap_confirm.dart';
export 'package:swappro/features/home/property_swap_select.dart';
export 'package:swappro/features/home/property_swap_select_belonging.dart';
export 'package:swappro/features/home/property_swap_confirm_yours.dart';
export 'package:swappro/features/home/property_swap_settlement_sheet.dart';
export 'package:swappro/features/home/property_swap_confirm_dash.dart';
export 'package:swappro/features/home/property_swap_complete.dart';
export 'package:swappro/features/home/swap_bay.dart';
export 'package:swappro/features/home/swap_commitment.dart';
export 'package:swappro/features/home/go_for_swap.dart';
export 'package:swappro/features/home/property_swap_image.dart';
export 'package:swappro/features/home/add_belonging.dart';
export 'package:swappro/features/home/add_wish.dart';
export 'package:swappro/features/home/add_belonging_spec_label.dart';
export 'package:swappro/features/home/add_belonging_details.dart';
export 'package:swappro/features/home/add_belonging_location_picker.dart';
export 'package:swappro/features/home/add_belonging_photos.dart';
export 'package:swappro/features/home/add_belonging_addons.dart';
export 'package:swappro/features/auth/authinit.dart';
export 'package:swappro/common_design/manage_screen_style.dart';
export 'package:swappro/common_design/settings_screen_style.dart';
export 'package:swappro/common_design/widgets/app_screen_top_bar.dart';
export 'package:swappro/common_design/widgets/ctabutton.dart';
export 'package:swappro/common_design/widgets/user_avatar.dart';
export 'package:swappro/features/auth/recoveraccount.dart';
export 'package:swappro/features/auth/resetpass.dart';
export 'package:swappro/features/auth/verifycode.dart';
export 'package:swappro/common_design/widgets/success.dart';
export 'package:swappro/common_design/widgets/trans_ctabutton.dart';
export 'package:swappro/features/intelligence/manage_intelligence.dart';
export 'package:swappro/features/settings/profile.dart';
export 'package:swappro/features/settings/profile_edit.dart';
export 'package:swappro/features/listings/listings.dart';
export 'package:swappro/features/listings/edit_listing.dart';
export 'package:swappro/features/listings/listing_actions.dart';
export 'package:swappro/features/settings/notification.dart';
export 'package:swappro/features/settings/security.dart';
export 'package:swappro/features/settings/help.dart';
export 'package:swappro/features/settings/two_factor_auth.dart';

export 'package:swappro/features/notifications/models/app_notification.dart';
export 'package:swappro/features/notifications/notifications_inbox.dart';

// Onboarding
export 'package:swappro/features/onboarding/ftu_onboarding.dart';
export 'package:swappro/features/onboarding/onboarding_service.dart';

// barrel.dart
export 'package:swappro/features/integrations/models/platform_embed_session.dart';
export 'package:swappro/features/integrations/widgets/embedded_platform_webview.dart';
export 'package:swappro/features/integrations/webview_url_resolver.dart';
// Icons import
export 'package:flutter_bloc/flutter_bloc.dart';

export 'package:iconify_flutter/iconify_flutter.dart';
export 'package:iconify_flutter/icons/mdi.dart';
export 'package:iconify_flutter/icons/ion.dart';
export 'package:iconify_flutter/icons/uil.dart';
export 'package:iconify_flutter/icons/majesticons.dart';
export 'package:iconify_flutter/icons/carbon.dart';
export 'package:iconify_flutter/icons/nimbus.dart';
export 'package:iconify_flutter/icons/material_symbols.dart';
export 'package:iconify_flutter/icons/fa6_solid.dart';
export 'package:iconify_flutter/icons/fluent_emoji_high_contrast.dart';
export 'package:iconify_flutter/icons/tabler.dart';
export 'package:iconify_flutter/icons/icons8.dart';
export 'package:iconify_flutter/icons/ph.dart';
export 'package:iconify_flutter/icons/ri.dart';
export 'package:iconify_flutter/icons/humbleicons.dart';
export 'package:iconify_flutter/icons/entypo.dart';
export 'package:iconify_flutter/icons/ep.dart';
export 'package:iconify_flutter/icons/uim.dart';
export 'package:swappro/icons/fluent.dart';
export 'package:swappro/icons/auth_icons.dart';

// Design Imports
export 'package:swappro/common_design/app_typography.dart';
export 'package:swappro/common_design/app_system_ui.dart';
export 'package:swappro/common_design/colors.dart';
export 'package:swappro/common_design/widgets/app_scaffold.dart';
export 'package:swappro/common_design/widgets/appbutton.dart';
export 'package:swappro/common_design/widgets/swappro_loading_indicator.dart';
export 'package:swappro/common_design/widgets/swap_lottie_view.dart';
export 'package:swappro/common_design/widgets/app_snackbar.dart';
export 'package:swappro/common_design/widgets/auth_form_field.dart';
export 'package:swappro/common_design/widgets/auth_screen_widgets.dart';
export 'package:swappro/common_design/widgets/auth_pin_field.dart';
export 'package:page_transition/page_transition.dart';
