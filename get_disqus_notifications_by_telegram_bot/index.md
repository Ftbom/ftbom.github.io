# 借助Zapier将Disqus通知推送到Telegram机器人


<div style="text-align: center;">
    <img src="/blog_images/disqus_telegram.png" alt="disqus_telegram.png">
</div>

之前博客的评论系统用的是[Valine](https://valine.js.org/)，最近发现不能用了，原来是LeanCloud限制长时间不使用自动冻结应用。为了省事，把博客的评论系统切换到了[Disqus](https://disqus.com/)。

Disqus提供了新评论通知的功能，但是只支持邮件通知、网页通知和Rss订阅三种方式。我并不想每次有新评论都收到邮件，Rss订阅又只支持订阅单个话题，于是就想找到通过Telegram收到新评论通知的方法。

最终通过[Zapier](https://zapier.com)实现了通过Telegram收到Disqus新评论通知的功能。

{{< admonition warning >}}
Zapier免费版每个月只支持运行100次任务，即免费版每个月最多只能收到100条通知
{{< /admonition >}}

## 准备工作

* 在Telegram上向[@BotFather](https://t.me/BotFather)申请机器人token；
* 在Telegram上通过[@userinfobot](https://t.me/userinfobot)获取用户id；
* 注册Zapier账号。

>Zapier上的Disqus连接器如果设置成同时获取多种类型的新评论，在运行时会报错。需要添加两个Zap分别处理已审批和待审批的新评论。

## 待审批的新评论

### 设置触发器

首先创建新的Zap，Trigger中的App event选择Disqus连接器，然后Event选择为New Comment。如图所示：

<div style="text-align: center;">
{{< image src="/blog_images/disqus_telegram1.png" alt="disqus_telegram1.png" >}}
</div>

点击Continue，授权Disqus账户，授权后如图所示：

<div style="text-align: center;">
{{< image src="/blog_images/disqus_telegram2.png" alt="disqus_telegram2.png" >}}
</div>

继续设置trigger，include选择Unapproved Posts，Forum选择要获取新评论通知的网站，如图所示：

<div style="text-align: center;">
{{< image src="/blog_images/disqus_telegram3.png" alt="disqus_telegram3.png" >}}
</div>

继续向下，测试trigger，获取网站上的待审批评论的数据。若网站尚未有评论，先自行在网站上发一条评论。
>匿名评论一般是待审批评论

### 设置响应动作

设置Zap的Action，App event选择Code by Zapier，Event选择Run Javascript，如图所示：

<div style="text-align: center;">
{{< image src="/blog_images/disqus_telegram4.png" alt="disqus_telegram4.png" >}}
</div>

Set up action中Input Data设置如下图：

<div style="text-align: center;">
{{< image src="/blog_images/disqus_telegram5.png" alt="disqus_telegram5.png" >}}
</div>

`tg_token`和`tg_chatid`分别填入准备工作中获取的token和id。

在Set up action的Code中填入以下代码：

```javascript
//Telegram机器人token
const TG_API_TOKEN = inputData.tg_token;

//chatid
const CHAT_ID = inputData.tg_chatid;

async function postData(url, data) {
  const response = await fetch(url, {
    method: 'POST', 
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(data)
  });
  return response.json();
}

const message = `<b>待审批消息</b>\n<b>用户名</b>：${inputData.user_name}\n<b>时间</b>：${inputData.date}\n<b>内容</b>：${inputData.message}\n<b>文章名</b>：${inputData.article}\n<b>文章链接</b>：${inputData.article_url}`;

console.log("Sending out", message);

const payload = {chat_id: CHAT_ID, text: message, disable_notification: false, parse_mode: "HTML"};

//Telegram API
const endpoint = `https://api.telegram.org/bot${TG_API_TOKEN}/sendMessage`;

//POST
const resp = await postData(endpoint, payload);

console.log("We got", resp);

//Zapier output
output = resp;
```

继续向下，点击Test action可以进行测试，接收待审核评论的消息效果如图：

<div style="text-align: center;">
{{< image src="/blog_images/disqus_telegram6.png" alt="disqus_telegram6.png" >}}
</div>

## 已审批/通过的新评论

创建一个新的Zap，设置步骤与待审批的新评论设置类似，仅在某些部分有一些更改：
* 设置trigger时include改为选择Approved Posts；
* Set up action中Input Data设置如下图，`admin_url`设置为Disqus用户主页的链接，如：`https://disqus.com/by/Ftbom/`
<div style="text-align: center;">{{< image src="/blog_images/disqus_telegram7.png" alt="disqus_telegram7.png" >}}</div>

* Set up action的Code中填入的代码改为：

```javascript
const TG_API_TOKEN = inputData.tg_token;

const CHAT_ID = inputData.tg_chatid;

async function postData(url, data) {
  const response = await fetch(url, {
    method: 'POST', 
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(data)
  });
  return response.json();
}

const message = `<b>新评论</b>\n<b>用户名</b>：${inputData.user_name}\n<b>时间</b>：${inputData.date}\n<b>内容</b>：${inputData.message}\n<b>文章名</b>：${inputData.article}\n<b>文章链接</b>：${inputData.article_url}`;

const payload = {chat_id: CHAT_ID, text: message, disable_notification: false, parse_mode: "HTML"};

const endpoint = `https://api.telegram.org/bot${TG_API_TOKEN}/sendMessage`;

var resp = {info: 'do nothing'};
if (inputData.isAnonymous == 'True')
{
  resp = {info: 'is anonymous'};
}
else if(inputData.profileUrl == inputData.admin_url)
{
  resp = {info: 'is admin'};
}
else
{
  console.log("Sending out", message);
  resp = await postData(endpoint, payload);
  console.log("We got", resp);
}

output = resp;
```

## 结语

经过上述步骤的设置，对于所有待审批的评论都通知；对于已审批/通过的评论，若发帖人是匿名用户或博主则不进行通知。

当网站上出现新评论后，大概延迟2-10分钟才会收到通知。
