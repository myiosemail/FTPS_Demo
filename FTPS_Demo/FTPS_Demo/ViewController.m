
#import "ViewController.h"
#import "SVProgressHUD.h"
@interface ViewController ()
@end
@implementation ViewController

#warning Need to be modified
#define kServer @"ftps://10.25.0.98:990"

struct myprogress {
    CURL *curl;
};
static int xferinfo(void *p,
                    curl_off_t dltotal, curl_off_t dlnow,
                    curl_off_t ultotal, curl_off_t ulnow)
{
    [SVProgressHUD showProgress:(float)ulnow/ultotal status:@"uploading"];
    return 0;
}
- (IBAction)uploadClick:(id)sender {
    NSString * localPath=[[NSBundle mainBundle]pathForResource:@"001.png" ofType:nil];
    NSString *uuid = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSString * serverPath=[NSString stringWithFormat:@"%@/%@_%@",kServer,uuid,localPath.lastPathComponent];
    [self uploadFileServerPath:serverPath localPath:localPath];
}
- (CURLcode)uploadFileServerPath:(NSString *)serverPath localPath:(NSString *)localPath {
    
    CURL *curl;
    CURLcode res;
    FILE *hd_src;
    struct stat file_info;
    curl_off_t fsize;

    /* get the file size of the local file */
    if(stat(localPath.UTF8String, &file_info)) {
        printf("Couldn't open '%s': %s\n", localPath.UTF8String, strerror(errno));
        return 1;
    }
    fsize = (curl_off_t)file_info.st_size;
    
    printf("Local file size: %lld CURL_FORMAT_CURL_OFF_T bytes.\n", fsize);
    
    /* get a FILE * of the same file */
    hd_src = fopen(localPath.UTF8String, "rb");
    
    /* In windows, this will init the winsock stuff */
    curl_global_init(CURL_GLOBAL_ALL);
    
    /* get a curl handle */
    curl = curl_easy_init();
    
    struct myprogress prog;
    
    prog.curl = curl;
    
    curl_easy_setopt(curl, CURLOPT_XFERINFOFUNCTION, xferinfo);
    
    curl_easy_setopt(curl, CURLOPT_XFERINFODATA, &prog);
    
    curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0L);
    
    /* enable uploading */
    curl_easy_setopt(curl, CURLOPT_UPLOAD, 1L);
    
    /* specify target */
    curl_easy_setopt(curl, CURLOPT_URL, serverPath.UTF8String);

#warning Need to be modified
    curl_easy_setopt(curl, CURLOPT_USERPWD, "001:001");//username:password
    
    /* now specify which file to upload */
    curl_easy_setopt(curl, CURLOPT_READDATA, hd_src);
    
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0);
    
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0);
    
    curl_easy_setopt(curl, CURLOPT_INFILESIZE_LARGE,
                     (curl_off_t)fsize);
    
    //At present, the server is supported to return the certificate without certificate verification.For more information, refer to curl official website.https://curl.haxx.se/libcurl/c/
    
    
    //   CA root certs - loaded into project from libcurl http://curl.haxx.se/ca/cacert.pem
    //   NSString *cacertPath = [[NSBundle mainBundle] pathForResource:@"cacert" ofType:@"pem"];
    //   curl_easy_setopt(curl, CURLOPT_CAINFO, [cacertPath UTF8String]); // set root CA certs
    
    res = curl_easy_perform(curl);
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    if (res==CURLE_OK) {
        [SVProgressHUD showSuccessWithStatus:@"upload success"];
        [SVProgressHUD dismissWithDelay:1];
    }else{
        [SVProgressHUD showErrorWithStatus:[NSString stringWithUTF8String:curl_easy_strerror(res)]];
        [SVProgressHUD dismissWithDelay:1];
    }
    /* always cleanup */
    curl_easy_cleanup(curl);
    fclose(hd_src); /* close the local file */
    curl_global_cleanup();
    return res;
}

@end
