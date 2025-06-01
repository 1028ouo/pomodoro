import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _forgotPasswordEmailController = TextEditingController();
  bool _isObscure = true;
  bool _isLogin = true; // 控制顯示登入或註冊表單
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // 新增生日相關變數
  DateTime? _selectedBirthday;
  final _birthdayController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _forgotPasswordEmailController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  // 選擇生日的方法
  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: '選擇您的生日',
      cancelText: '取消',
      confirmText: '確定',
      fieldLabelText: '生日日期',
      fieldHintText: '年/月/日',
      errorFormatText: '請輸入有效的日期',
      errorInvalidText: '請輸入有效的日期範圍',
    );

    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
        _birthdayController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // 處理登入
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      try {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('登入處理中...')));

        // 使用 email 而不是 username 登入
        final result = await _authService.login(
          _usernameController.text, // 這裡使用 username 欄位輸入 email
          _passwordController.text,
        );

        if (result['success']) {
          if (mounted) {
            // 清除登入中訊息
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('登入成功！')));

            // 導航到首頁
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('登入失敗: ${result['message']}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('登入失敗: ${e.toString()}')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // 處理註冊
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      try {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('註冊處理中...')));

        final result = await _authService.register(
          _usernameController.text,
          _emailController.text,
          _passwordController.text,
          _birthdayController.text, // 傳遞生日資料
        );

        if (result['success']) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('註冊成功! 請登入')));
            setState(() {
              _isLogin = true;
              _passwordController.clear();
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('註冊失敗: ${result['message']}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('發生錯誤: ${e.toString()}')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // 顯示忘記密碼對話框
  void _showForgotPasswordDialog() {
    _forgotPasswordEmailController.clear(); // 清除之前的輸入

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('重設密碼'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('請輸入你的電子郵件地址，我們會發送重設密碼的連結給你。'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _forgotPasswordEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '電子郵件',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  if (_forgotPasswordEmailController.text.isNotEmpty) {
                    _handleForgotPassword();
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('請輸入電子郵件')));
                  }
                },
                child: const Text('送出'),
              ),
            ],
          ),
    );
  }

  // 處理忘記密碼請求
  Future<void> _handleForgotPassword() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('處理中...')));

      final result = await _authService.forgotPassword(
        _forgotPasswordEmailController.text,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? '重設密碼連結已發送至您的電子郵件')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('失敗: ${result['message']}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('發生錯誤: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 處理Google登入
  Future<void> _handleGoogleSignIn() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Google登入處理中...')));

      final result = await _authService.signInWithGoogle();

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Google登入成功！')));

          // 登入成功後導航到首頁
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Google登入失敗: ${result['message']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('發生錯誤: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Pomodoro',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _usernameController,
                    keyboardType:
                        _isLogin
                            ? TextInputType.emailAddress
                            : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: _isLogin ? '電子郵件' : '用戶名',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(_isLogin ? Icons.email : Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _isLogin ? '請輸入電子郵件' : '請輸入用戶名';
                      }
                      if (_isLogin && !value.contains('@')) {
                        return '請輸入有效的電子郵件';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 只在註冊模式顯示電子郵件輸入框
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: '電子郵件',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '請輸入電子郵件';
                        }
                        if (!value.contains('@')) {
                          return '請輸入有效的電子郵件';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // 新增生日輸入欄位
                    TextFormField(
                      controller: _birthdayController,
                      readOnly: true,
                      onTap: () => _selectBirthday(context),
                      decoration: const InputDecoration(
                        labelText: '生日',
                        hintText: '點擊選擇生日',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '請選擇您的生日';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: '密碼',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscure = !_isObscure;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '請輸入密碼';
                      }
                      if (!_isLogin && value.length < 6) {
                        return '密碼至少需要6個字符';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading ? null : (_isLogin ? _login : _register),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : Text(
                                _isLogin ? '登入' : '註冊',
                                style: const TextStyle(fontSize: 18),
                              ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 添加Google登入按鈕
                  if (_isLogin) ...[
                    Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('或'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        icon: Image.network(
                          'https://developers.google.com/identity/images/g-logo.png',
                          height: 24.0,
                        ),
                        label: const Text('使用 Google 登入'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 15),
                  if (_isLogin)
                    TextButton(
                      onPressed: () {
                        _showForgotPasswordDialog();
                      },
                      child: const Text('忘記密碼？'),
                    ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _formKey.currentState?.reset();
                      });
                    },
                    child: Text(_isLogin ? '沒有帳號？註冊' : '已有帳號？登入'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
