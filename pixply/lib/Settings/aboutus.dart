import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:led_ble_lib/led_ble_lib.dart';
import 'package:url_launcher/url_launcher.dart';

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  const _SectionBody(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Poppins',
          fontSize: 14,
          height: 1.45,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _AboutHeader extends StatelessWidget {
  final String title;
  const _AboutHeader(this.title);

  @override
  Widget build(BuildContext context) {
    const double leftPadding = 16.0;
    return SizedBox(
      height: 92,
      child: Stack(
        children: [
          const Center(
            child: Text(
              'About Us',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Positioned(
            left: leftPadding,
            top: 10,
            child: Container(
              width: 71,
              height: 71,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
              child: IconButton(
                icon: SvgPicture.asset('assets/arrow.svg', width: 36, height: 36),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// Simple expandable group for many names
class _BackersGroup extends StatelessWidget {
  final String title;
  final List<String> names;
  const _BackersGroup({required this.title, required this.names});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        collapsedIconColor: Colors.white70,
        iconColor: Colors.white70,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        children: [
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: names.map((n) => _BackerChip(name: n)).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _BackerChip extends StatelessWidget {
  final String name;
  const _BackerChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2F2F2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x3393FF83)),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Poppins',
          fontSize: 12,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class AboutUsPage extends StatefulWidget {
  final LedBluetooth bluetooth;
  final bool isConnected;

  const AboutUsPage({
    super.key,
    required this.bluetooth,
    required this.isConnected,
  });

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {

  // Stage 2: parsed names for a nicer grid (standardized the two names)
  static const List<String> backers = <String>[
    r'Michael Sager', r'Benjamin Wakefield', r'Lazzarotto', r'Alan Lewis', r'Alham Mohamad Ali',
    r'Tim Roberts', r'Rachel Johnson', r'Lydell Capritta', r'Kandarp Janí', r'Alex',
    r'Aaron Weekes', r'Odintsov Denis Sheehy', r'Stuart', r'James Pacheco', r'Mustafa Al-Bayati',
    r'Nicholas Hollands', r'Ben', r'Ian Jones', r'Valerio Ciotti', r'Greg Shackleford',
    r'Steve Broughton', r'Paul Gimson', r'Carl Testa', r'Dawn-Marie Eyles', r'Robert Witton',
    r'Robert Bass', r'Ranulf Corbett', r'Stephanie Plunkett', r'Silvio Douven', r'Hannah Stilwell',
    r'Christian Olney', r'Steve Giller', r'James Hayward', r'Mick Wood', r'Tim Philippou',
    r'Kate Ward', r'David Wegg', r'Peter Everitt', r'Sarah Ellis', r'Kevin Travers',
    r'David Parker', r'Matt Davy', r'Allan Matthews', r'Sunil Gopisetty', r'Duncan Reeves',
    r'Craig Newkirk', r'Anthony Osborne', r'Daryl Walker-Smith', r'Lisa Wall', r'Andy Havens',
    r'Rishi Mannan', r'Simon Grimshaw', r'Colton Wagner', r'Nik Whitehead', r'Philip Maidens',
    r'Daniel Lynch', r'Chanté Williamson', r'Ryan Daugherty', r'Rafael Ojeda Polito', r'Demi Pardalis',
    r'Archaic Games', r'Elizabeth Tilley', r'Graham Boldt', r'Mirko Scheske', r'Duncan Cumming',
    r'Tanner Grimshaw', r'Mr Ian Fox', r'Jimmy Brough', r'Natalie Dandekar', r'Abbas Sabeti',
    r'Adam Landes', r'Graham Heath', r'Brian Bacharz', r'Daniel Friedman', r'Joe Burnip',
    r'Stephanie Butters', r'Yuya Miyamoto', r'Otto Yu', r'Fabian Fromm', r'James Cox',
    r'Eliot Cholerton-Hill', r'Jack Loiodice', r'Nick Ford', r'Hiu Ying Alison Cheuk', r'Glen Marsh',
    r'Judah Warshaw', r'Christoph Pohl', r'Tim Williams', r'Matthew Perryman', r'Dennis Rohe',
    r'Vinay Ashwin', r'Matt Dowding', r'Liam Murphy', r'Ivan Castelo', r'Doreen Wendt',
    r'Carl Niclas Abel', r'Alan Young', r'Dante Dicerchio', r'Andrew Tolton', r'Caitlin McCarthy',
    r'Elizabeth Ann Bergman', r'Oliver', r'Brian Hadley', r'Sharlene Kerr', r'Dan Shannon',
    r'Tylor', r'Lee Peverett', r'Gavin Tillman', r'Ana Torres', r'Bruno Esteves',
    r'Craig Zoll', r'Jack Gulick', r'Angel Covarrubias', r'Rasteen Nowroozi', r'Phillip Rubenstein',
    r'Dexter Hailey', r'Alexander Graf', r'Whitney Allen', r'Abhishek Madhavan', r'Ava L',
    r'Conley Burns', r'Lorenz Trippel', r'Barry Seed', r'Aphirak Pich', r'Kevin (Deleesha) Park (Cains)',
    r'Caroline Green', r'Paul Andrews', r'German Palomino', r'Alexandre Abraham', r'LuisFer Padrón',
    r'Andrea Simonella', r'Benjamin Justham', r'Edmund Misiakiewicz', r'Richard Ensign', r'Sing Sing Teoh',
    r'Richard Newton', r'Mel Reilly', r'Stephanie Emmett', r'Scott Christopher', r'Stefan Jönsson',
    r'Maija Reed', r'Alan Maignan', r'Thomas Ernet', r'Rebecca Floyd', r'Daisuke Utsumi',
    r'Richard Boothroyd', r'Cezary Glijer', r'Thomas Resch', r'Meg Dunbar', r'Mat Aston',
    r'Filipe Alves', r'Pouriya Ghasemi', r'Jordi Lopez Diaz', r'Andrew Hayden', r'Kyle Peacock',
    r'Jesper Helmin', r'Chiara Burattoni', r'John Zacharakis', r'Igor Bizjak', r'Jason Gibson',
    r'Karan Mehta', r'Alexander Shen', r'Joe Hughes', r'Jeff Bradshaw', r'John Miller',
    r'Reem Kopitman', r'Alexandre Aleixo Pereira', r'William Paradis', r'Paul Sciberras', r'Pavel Mitáš',
    r'Jermaine Thompson', r'Natalia Farre Lopez', r'Gian-Luca Beck', r'Laura Labello', r'Teo Xing Zhi',
    r'Torsten Parulewski', r'Dasbach Christian', r'Gerhard Bierleutgeb', r'Massimiliano Valentino', r'Anna Bickham',
    r'Linda Mattoon', r'Erik Fischer', r'Jeremy Carr', r'Patty Voga', r'Carlo Rossato',
    r'Dominic Volk', r'Sandro Schmidt', r'Kevin Geddis', r'Atticus Speis', r'Didier Cotton',
    r'Nova Faham', r'Gregory Floch', r'Pedro Miguel Alves da Costa', r'Holli Robertson', r'Preacco Igor',
    r'Marek Salurand', r'Dominic Hanaman', r'Sujima Viravaidya', r'Ole Nielsen', r'Deb Thomas',
    r'Sebastian Jespersen', r'Mary Wills Shaler', r'Joshua Tratner', r'Egbert Hommels', r'Reign Gray',
    r'Kris Gould', r'Abdel Olmeda Rosado', r'Kylar Black', r'Jason Shin', r'Christopher Dadd',
    r'Jai Mehta', r'Ali Khallaghi', r'Steve Jenkinson', r'Amanda Dice', r'David Freeman',
    r'David Romard', r'Henry Pi', r'Douglas Gillespie', r'Matt Rossi', r'Le Anh My Tran',
    r'Jennifer Baum', r'Pablo Romero', r'Virginia', r'Sarah Gomes Monteiro', r'Carmen Bovard',
    r'Alexander Halkjær', r'Rui Delgado Alves', r'Gordon Zomack', r'Leif Fredby', r'Liam Flynn',
    r'Bastian Rother', r'Elijah Brandley', r'Kristen Pedersen Wilson', r'Todd West', r'Sebastian Patiño Barrientos',
    r'Sean Chen Liu', r'Harrison Squire', r'Dream Diamond Games', r'Michael Ross', r'Caleigh Master',
    r'Daniel Lorenz', r'Waqar Hussain', r'James Fitzpatrick', r'Quan Vuong', r'Debbie Yee',
    r'Henrik Bruns', r'Andrea Kim', r'Richard Stephenson', r'Uwe Backes', r'Kevin Voga',
    r'久保将輝', r'Matthias Tidlund', r'Rahn', r'Kat McKay', r'Devina Soekamto',
    r'Grant Nitchals', r'Michael Zenkner', r'Yorick Bailer', r'Loralei ThornBurg', r'Frank Hansen',
    r'Fumitaka Sato', r'Ivan Dimitrijevic', r'Sean Jerig', r'Christian Heuser', r'Stephen J. Somers',
    r'Michael Goedhart', r'Costin Daniel', r'Thanomsing Kosolnavin', r'Ariel Ruiz', r'Steven Alan Fischkoff',
    r'Greg Loumeau', r'Maximilian Warden', r'Chris Lowe', r'Viktor Mangazeev', r'Lars Schumann',
    r'Vera Zeguers-Habets', r'Dan Iavorszky', r'Matteo Macrì', r'Alex Kujundzic', r'Francis W. Murphy',
    r'Jeremy Austin Clewell', r'Jurijs Oleinikovs', r'Karel Berka', r'Ignacio Bonet Cifuentes', r'Mai Natou',
    r'Andrew Paciga', r'Anna Segal', r'Daniel Husmer', r'Jen Maddison', r'Miguel Lopez',
    r'Virando', r'Joost Vermeulen', r'Cobac', r'Robert Kränzlein', r'Armand Mario Sellier',
    r'George L. Lee', r'Angel Mario Gato Gutierrez', r'Shai Schwartz', r'Marcel Jílek', r'Vladyslav Korniienko',
    r'Mandel Ilagan', r'Chris Tuffin', r'Nicholas Earley', r'Kimberly Uken Coble', r'Isabel Howat',
    r'David Castro', r'Sven Flückiger', r'Daniele Bartocci', r'Yuya Kotani', r'Mauriac Sodjinou',
    r'Camille Tisdel', r'Rob Goode', r'Tonja Djuren', r'Philippe Dass', r'Richard J.N. Brewer',
    r'Beh Kok Seng', r'Snoppythe3', r'Sören Leder', r'Rob Chapman', r'Bernd Fischer',
    r'Andreas Krause', r'Jeremy Deutsch', r'William Bradley', r'Vasileios Iliadis', r'Willing Camden',
    r'Jeffrey Pratt Gordon', r'Barillere Melanie', r'Lebo Isabelle', r'Fabian Schocke', r'Alaq Rahman',
    r'Rosamund Anne Russell', r'Conor Preece', r'Cori', r'Manuel Wilfredo Gomez Melendez', r'Matti Seila',
    r'Andrew Johnson', r'Emil Schneider', r'Jill Hubbard', r'Teus Kappen', r'Peter McManus',
    r'Bruno Eveillard', r'Jesse Imber', r'Cesar', r'Karthik Subramaniyam', r'Stephen Tihor',
    r'Madalin Sava', r'Neon John Douglass', r'Brendan Burrows', r'Crista McDonough', r'Sascha Morandin',
    r'Chris Kemmer', r'Anne Buckley', r'Andrew Miller', r'Laxman Murugappan', r'Owen Thompson',
    r'Cassandra Schellhas', r'Dan Witthøft', r'Anika Fairooz Chowdhury', r'Aaron Min',
  ];


  Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Widget _buildMenuButton(String label, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(52.5),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}


@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color.fromRGBO(49, 49, 49, 1),
    body: SafeArea(
      child: Column(
        children: [
          const _AboutHeader('About Us'),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.20),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMenuButton(
                    'Terms of Use',
                    () => _openUrl(
                      'https://www.pixply.io/pixply-app-terms-and-conditions',
                    ),
                  ),
                  _buildMenuButton(
                    'Privacy Policy',
                    () => _openUrl(
                      'https://www.pixply.io/pixply-app-privacy-policy',
                    ),
                  ),
                  _buildMenuButton(
                    'Declarations',
                    () => _openUrl(
                      'https://www.pixply.io/pixply-app-declerations',
                    ),
                  ),
                  _buildMenuButton(
                    'Backer Appreciation',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BackerAppreciationPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


}
class BackerAppreciationPage extends StatelessWidget {
  const BackerAppreciationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(49, 49, 49, 1),
      body: SafeArea(
        child: Column(
          children: [
            const _AboutHeader('About Us'),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0),
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.20),
              ),
            ),
            const SizedBox(height: 20),
          Expanded(
  child: ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
    children: [
      _SectionTitle('Thank You to Our Founding Backers'),
      _SectionBody(
        'Pixply exists because of our incredible community — '
        'from early Kickstarter backers to new players discovering it today. '
        'Thank you for believing in this vision and helping bring it to life. '
        'Each of your names is part of this journey, and together, you are '
        'the foundation of the Pixply community.',
      ),
      const SizedBox(height: 12),
      _BackersGroup(
        title: 'Backers',
        names: _AboutUsPageState.backers,
      ),
    ],
  ),
),


          ],
        ),
      ),
    );
  }
}

