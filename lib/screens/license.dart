import 'package:flutter/material.dart';

class CustomLicensePage extends StatelessWidget {
  const CustomLicensePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ライセンス情報'),
      ),
      body: ListView(
        children: [
          _buildLicenseSection(
            'cupertino_icons',
            'MIT License',
            'Copyright (c) 2016 Vladimir Kharlampidi',
          ),
          _buildLicenseSection(
            'flutter_colorpicker',
            'MIT License',
            'Copyright (c) 2021 fuyumi',
          ),
          _buildLicenseSection(
            'provider',
            'MIT License',
            'Copyright (c) 2019 Remi Rousselet',
          ),
          _buildLicenseSection(
            'geolocator',
            'MIT License',
            'Copyright (c) 2018 Baseflow',
          ),
          _buildLicenseSection(
            'sign_in_button',
            'MIT License',
            'Copyright (C) 2018, Zayn Jarvis',
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseSection(
      String packageName, String licenseType, String copyrightNotice) {
    return ExpansionTile(
      title: Text(packageName),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(licenseType, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(copyrightNotice),
              SizedBox(height: 16),
              Text(
                  'Permission is hereby granted, free of charge, to any person obtaining a copy '
                  'of this software and associated documentation files (the "Software"), to deal '
                  'in the Software without restriction, including without limitation the rights '
                  'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell '
                  'copies of the Software, and to permit persons to whom the Software is '
                  'furnished to do so, subject to the following conditions:\n\n'
                  'The above copyright notice and this permission notice shall be included in all '
                  'copies or substantial portions of the Software.\n\n'
                  'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR '
                  'IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, '
                  'FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE '
                  'AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER '
                  'LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, '
                  'OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE '
                  'SOFTWARE.'),
            ],
          ),
        ),
      ],
    );
  }
}
