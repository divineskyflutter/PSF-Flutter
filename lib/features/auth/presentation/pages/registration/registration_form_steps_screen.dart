import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/routes/app_routes.dart';

class RegistrationFlowScreen extends StatefulWidget {
  const RegistrationFlowScreen({super.key});
  @override
  State<RegistrationFlowScreen> createState() => _RegistrationFlowScreenState();
}

class _RegistrationFlowScreenState extends State<RegistrationFlowScreen> {
  final _pageController = PageController();
  final _personalForm = GlobalKey<FormState>();
  final _nomineeForm = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _father = TextEditingController();
  final _mobile = TextEditingController();
  final _address = TextEditingController();
  final _dob = TextEditingController();
  final _aadhaar = TextEditingController();
  final _nomineeName = TextEditingController();
  final _nomineeRelation = TextEditingController();
  final _nomineeMobile = TextEditingController();
  int _step = 0;
  String _gender = 'male';
  String? _photoPath;
  String? _aadhaarPath;
  bool _acceptedTerms = false;
  final List<Nominee> _nominees = [];

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in [
      _name,
      _father,
      _mobile,
      _address,
      _dob,
      _aadhaar,
      _nomineeName,
      _nomineeRelation,
      _nomineeMobile
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _chooseFile(bool photo) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result?.files.single.path != null && mounted)
      setState(() {
        if (photo)
          _photoPath = result!.files.single.path;
        else
          _aadhaarPath = result!.files.single.path;
      });
  }

  void _next() {
    if (_step == 0 && !(_personalForm.currentState?.validate() ?? false))
      return;
    if (_step == 1) {
      if (!(_nomineeForm.currentState?.validate() ?? false)) return;
      _nominees.add(Nominee(
          name: _nomineeName.text.trim(),
          relationship: _nomineeRelation.text.trim(),
          mobile: _nomineeMobile.text.trim()));
    }
    if (_step == 2 && !_acceptedTerms) {
      Get.snackbar('required'.tr, 'accept_terms_error'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_step == 2) {
      _openPreview();
      return;
    }
    setState(() => _step++);
    _pageController.animateToPage(_step,
        duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  void _openPreview() {
    final application = RegistrationApplication(
        fullName: _name.text.trim(),
        fatherName: _father.text.trim(),
        mobile: _mobile.text.trim(),
        address: _address.text.trim(),
        dateOfBirth: _dob.text.trim(),
        gender: _gender,
        aadhaarNumber: _aadhaar.text.trim(),
        photoPath: _photoPath,
        aadhaarPath: _aadhaarPath,
        nominees: _nominees,
        acceptedTerms: _acceptedTerms);
    Get.toNamed(AppRoutes.registrationPreview, arguments: application);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
            child: Column(children: [
          _topBar(),
          Expanded(
              child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [_personalStep(), _nomineeStep(), _reviewStep()])),
          _bottomButton(),
        ])),
      );

  Widget _topBar() => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(children: [
        Row(children: [
          IconButton(
              onPressed: () {
                if (_step == 0)
                  Get.back();
                else {
                  setState(() => _step--);
                  _pageController.animateToPage(_step,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut);
                }
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19)),
          const Spacer(),
          Text('${'step'.tr} ${_step + 1}/3',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
          const Spacer(),
          const SizedBox(width: 48)
        ]),
        const SizedBox(height: 8),
        LinearProgressIndicator(
            value: (_step + 1) / 3,
            minHeight: 6,
            borderRadius: BorderRadius.circular(8),
            color: AppColors.primary,
            backgroundColor: AppColors.primary.withOpacity(.14)),
      ]));

  Widget _personalStep() => _scroll(Form(
      key: _personalForm,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title('personal_information'.tr, 'personal_information_hint'.tr),
        _field(_name, 'full_name'.tr, Icons.person_outline),
        _field(_father, 'fathers_name'.tr, Icons.person_outline),
        _field(_mobile, 'phone_number'.tr, Icons.phone_outlined,
            keyboard: TextInputType.phone, digits: 10),
        _field(_dob, 'date_of_birth'.tr, Icons.calendar_today_outlined),
        _field(_address, 'address'.tr, Icons.location_on_outlined, maxLines: 3),
        _field(_aadhaar, 'aadhaar_number'.tr, Icons.badge_outlined, digits: 12),
        Text('gender'.tr, style: _labelStyle),
        Row(
            children: ['male', 'female', 'other']
                .map((value) => Expanded(
                    child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: value,
                        groupValue: _gender,
                        title: Text(value.tr),
                        activeColor: AppColors.primary,
                        onChanged: (value) =>
                            setState(() => _gender = value!))))
                .toList()),
        _upload('profile_photo'.tr, _photoPath, () => _chooseFile(true)),
        _upload('aadhaar_photo'.tr, _aadhaarPath, () => _chooseFile(false)),
      ])));

  Widget _nomineeStep() => _scroll(Form(
      key: _nomineeForm,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title('nominee_details'.tr, 'nominee_hint'.tr),
        _field(_nomineeName, 'nominee_name'.tr, Icons.person_outline),
        _field(_nomineeRelation, 'relationship'.tr, Icons.people_outline),
        _field(_nomineeMobile, 'phone_number'.tr, Icons.phone_outlined,
            keyboard: TextInputType.phone, digits: 10),
        Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration,
            child: Row(children: [
              const Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('nominee_note'.tr,
                      style: const TextStyle(height: 1.4)))
            ])),
      ])));

  Widget _reviewStep() =>
      _scroll(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _title('confirm_information'.tr, 'confirm_information_hint'.tr),
        _summaryCard('personal_information'.tr,
            [_name.text, _mobile.text, _aadhaar.text]),
        _summaryCard(
            'nominee_details'.tr,
            _nominees.isEmpty
                ? ['nominee_will_be_added'.tr]
                : _nominees
                    .map((item) => '${item.name} - ${item.relationship}')
                    .toList()),
        CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _acceptedTerms,
            activeColor: AppColors.primary,
            onChanged: (value) =>
                setState(() => _acceptedTerms = value ?? false),
            title: Text('agree_terms'.tr,
                style: const TextStyle(fontSize: 14, height: 1.35))),
      ]));

  Widget _bottomButton() => SafeArea(
      top: false,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: Text(_step == 2 ? 'preview_application'.tr : 'next'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w700))))));
  Widget _scroll(Widget child) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16), child: child);
  Widget _title(String title, String caption) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark)),
        const SizedBox(height: 7),
        Text(caption,
            style: TextStyle(
                color: AppColors.primaryDark.withOpacity(.65), height: 1.4))
      ]));
  final _labelStyle = const TextStyle(
      fontWeight: FontWeight.w600, color: AppColors.primaryDark);
  Widget _field(TextEditingController controller, String label, IconData icon,
          {TextInputType? keyboard, int? digits, int maxLines = 1}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
              controller: controller,
              keyboardType: keyboard,
              maxLength: digits,
              maxLines: maxLines,
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return 'field_required'.tr;
                if (digits != null &&
                    value.replaceAll(RegExp(r'\\D'), '').length != digits)
                  return 'invalid_number'.tr;
                return null;
              },
              decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon),
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: const BorderSide(color: AppColors.border)))));
  BoxDecoration get _cardDecoration => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border));
  Widget _upload(String label, String? path, VoidCallback select) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
          onTap: select,
          borderRadius: BorderRadius.circular(14),
          child: Container(
              height: 76,
              padding: const EdgeInsets.all(12),
              decoration: _cardDecoration,
              child: Row(children: [
                if (path != null)
                  ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(path),
                          width: 52, height: 52, fit: BoxFit.cover))
                else
                  const Icon(Icons.cloud_upload_outlined,
                      color: AppColors.primary, size: 30),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(path == null ? label : 'file_selected'.tr,
                        style: _labelStyle)),
                Icon(Icons.chevron_right,
                    color: AppColors.primaryDark.withOpacity(.5))
              ]))));
  Widget _summaryCard(String heading, List<String> lines) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(heading, style: _labelStyle),
        const SizedBox(height: 8),
        ...lines.map((item) => Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(item,
                style:
                    TextStyle(color: AppColors.primaryDark.withOpacity(.7)))))
      ]));
}
